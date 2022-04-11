{{/*
Copyright 2019 The Openstack-Helm Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/}}

{{- define "helm-toolkit.scripts.generic_health_probe" }}
#!/usr/bin/env python

"""
Health probe script for OpenStack agents that perform generic openstack service
check.

* Check if sockets are established to rabbitmq/database services

Usage example for octavia:
# python generic-health-probe.py
#   --process-name octavia-health-manager
#   --probe-type liveness
#   --config-file /etc/octavia/octavia.conf
#   --check database_sockets --check rabbitmq_sockets
"""

import argparse
import glob
import hashlib
import json
import logging
import os
import psutil
import socket
import sys

from six.moves.urllib import parse as urlparse

rpc_timeout = int(os.getenv('RPC_PROBE_TIMEOUT', '60'))
rpc_retries = int(os.getenv('RPC_PROBE_RETRIES', '2'))
rabbit_port = 5672
mysql_port = 3306
tcp_established = "ESTABLISHED"
tcp_syn = "SYN_SENT"
OSLO_CONF_OBJECT = None

logging.basicConfig(level=logging.INFO, stream=sys.stdout)
LOG = logging.getLogger(__file__)


def get_rabbitmq_ports():
    "Get RabbitMQ ports"
    import oslo_messaging

    rabbitmq_ports = set()
    try:
        transport_url = oslo_messaging.TransportURL.parse(OSLO_CONF_OBJECT)
        for host in transport_url.hosts:
            rabbitmq_ports.add(host.port)
    except Exception as ex:
        rabbitmq_ports.add(rabbit_port)
        message = getattr(ex, "message", str(ex))
        LOG.info("Health probe caught exception reading "
                 "RabbitMQ ports: %s", message)
    return list(rabbitmq_ports)


def get_database_ports():
    "Get Database ports"
    from oslo_db import options as db_opts

    db_opts.set_defaults(OSLO_CONF_OBJECT)
    connection = urlparse.urlparse(OSLO_CONF_OBJECT.database.connection)
    if not connection:
        LOG.info("Skipping probe, can't find database ports")
        return True
    host = connection.netloc.split('@')[1]
    split_host = host.split(':')
    port = split_host[1] if len(split_host) > 1 else 3306
    return [int(port)]


def get_libvirt_ports():
    "Get Libvirt ports"
    from oslo_config import cfg

    grp = cfg.OptGroup('libvirt')
    opts = [cfg.StrOpt('connection_uri')]
    OSLO_CONF_OBJECT.register_group(grp)
    OSLO_CONF_OBJECT.register_opts(opts, group=grp)

    connection_uri = OSLO_CONF_OBJECT.libvirt.connection_uri
    connection = urlparse.urlparse(connection_uri)

    return [int(connection.port or 16509)]


def is_connected_to(process_name, ports):
    for pr in psutil.pids():
        try:
            p = psutil.Process(pr)
            if any(process_name in cmd for cmd in p.cmdline()):
                pcon = p.connections()
                for con in pcon:
                    try:
                        port = con.raddr[1]
                        status = con.status
                    except IndexError:
                        continue
                    if port in ports and status in [tcp_established, tcp_syn]:
                        return True
        except psutil.NoSuchProcess:
            continue


def hash_config_files(hasher, args):
    for cfile in args.config_file:
        with open(cfile, "rb") as f:
            hasher.update(f.read())


def hash_config_dirs(hasher, args):
    for cdir in args.config_dir:
        config_dir_glob = os.path.join(cdir, '*.conf')
        for fname in sorted(glob.glob(config_dir_glob)):
            with open(fname, "rb") as f:
                hasher.update(f.read())


def check_connect(path):
    connections = psutil.net_connections('unix')
    addrs = [i.laddr for i in connections]
    return all(i in addrs for i in path)

def check_path_extsts(path):
    for p in path:
        if not os.path.exists(p):
            return False
    return True

def parse_args():
    parser = argparse.ArgumentParser(description="Generic health probe")
    parser.add_argument(
        "--probe-type", required=True, help="The type of a probe to execute.",
        choices=["liveness", "readiness"])
    parser.add_argument(
        "--process-name", required=True,
        help="The name of the process to check.")
    parser.add_argument(
        "--check", choices=["database_sockets", "rabbitmq_sockets",
                            "unix_sockets", "libvirt_connection"],
        help="The type of checks to perform.", action="append")
    parser.add_argument(
        "--config-file", help="Path to the service configfile(s).",
        action="append", default=[])
    parser.add_argument(
        "--config-dir", help="Path to the service configdir(s).",
        action="append", default=[])
    parser.add_argument(
        "--path", help="Path to the service socket file.",
        action="append", default=[])
    return parser.parse_args()


def set_oslo_conf_object(args):
    global OSLO_CONF_OBJECT
    if OSLO_CONF_OBJECT is not None:
        return
    from oslo_config import cfg
    args_list = []
    # We don't care whether some config dirs were passed to command line before
    # config files or in between, this is the order in which oslo_config does
    # the parsing
    for cfile in args.config_file:
        args_list.extend(["--config-file", cfile])
    for cdir in args.config_dir:
        args_list.extend(["--config-dir", cdir])
    cfg.CONF(args_list)
    OSLO_CONF_OBJECT = cfg.CONF


if __name__ == "__main__":
    args = parse_args()
    hasher = hashlib.sha256()
    # We don't handle default_config_files and default_config_dirs from
    # oslo_config as we do not set project name and we should not care
    # about program name configs (program name is generic-health-probe,
    # so default configs would be in places like /etc/generic-health-probe)
    hash_config_files(hasher, args)
    hash_config_dirs(hasher, args)
    conf_hash = hasher.hexdigest()
    cached_ports = {}
    try:
        with open("/tmp/generic_health_probe_cache", "rt") as ports_file:
            cached_ports = json.load(ports_file)
        if conf_hash != cached_ports["conf_hash"]:
            cached_ports = {}
    except Exception:
        pass

    if 'database_sockets' in args.check:
        if not cached_ports.get("database_ports"):
            set_oslo_conf_object(args)
            cached_ports["conf_hash"] = None
            cached_ports["database_ports"] = get_database_ports()
        if not is_connected_to(
                args.process_name, cached_ports["database_ports"]):
            LOG.error("Connection to database is not established.")
            sys.exit(1)
    if 'rabbitmq_sockets' in args.check:
        if not cached_ports.get("rabbitmq_ports"):
            set_oslo_conf_object(args)
            cached_ports["conf_hash"] = None
            cached_ports["rabbitmq_ports"] = get_rabbitmq_ports()
        if not is_connected_to(
                args.process_name, cached_ports["rabbitmq_ports"]):
            LOG.error("Connection to rabbitmq is not established.")
            sys.exit(1)
    if 'unix_socket' in args.check:
        if not args.path:
            LOG.error("Socket path is not set. Could not verify.")
            sys.exit(1)
        if not check_connect(args.path):
            LOG.error("Socket %s is not connected.", args.path)
            sys.exit(1)
    if 'libvirt_connection' in args.check:
        if not cached_ports.get("libvirt_port"):
            set_oslo_conf_object(args)
            cached_ports["conf_hash"] = None
            cached_ports["libvirt_port"] = get_libvirt_ports()
        if not is_connected_to(
                args.process_name, cached_ports["libvirt_port"]):
            LOG.error("Connection to libvirt is not established.")
            sys.exit(1)
    if not cached_ports.get("conf_hash"):
        cached_ports["conf_hash"] = conf_hash
        with open("/tmp/generic_health_probe_cache", "wt") as ports_file:
            json.dump(cached_ports, ports_file)
{{- end }}

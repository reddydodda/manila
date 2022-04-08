#!/bin/bash

{{/*
Copyright 2017 The Openstack-Helm Authors.

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

set -x
if [ "x$STORAGE_BACKEND" == "xmanila.share.drivers.cephfs.driver.CephFSDriver" ]; then
  SECRET=$(mktemp --suffix .yaml)
  KEYRING=$(mktemp --suffix .keyring)
  function cleanup {
      rm -f ${SECRET} ${KEYRING}
  }
  trap cleanup EXIT
fi

set -ex
if [ "x$STORAGE_BACKEND" == "xmanila.share.drivers.cephfs.driver.CephFSDriver" ]; then
  ceph -s

  if USERINFO=$(ceph auth get client.${CEPHFS_USER}); then
    echo "Cephx user client.${CEPHFS_USER} already exist."
    echo "Update its cephx caps"
    ceph auth caps client.${CEPHFS_USER} \
      mds "allow *" \
      osd "allow rw" \
      mon "allow r, allow command \"auth del\", allow command \"auth caps\", allow command \"auth get\", allow command \"auth get-or-create\""
    ceph auth get client.${CEPHFS_USER} -o ${KEYRING}
  else
    ceph auth get-or-create client.${CEPHFS_USER} \
      mds "allow *" \
      osd "allow rw" \
      mon "allow r, allow command \"auth del\", allow command \"auth caps\", allow command \"auth get\", allow command \"auth get-or-create\"" \
      -o ${KEYRING}
  fi
  ENCODED_KEYRING=$(sed -n 's/^[[:blank:]]*key[[:blank:]]\+=[[:blank:]]\(.*\)/\1/p' ${KEYRING} | base64 -w0)
  cat > ${SECRET} <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: "${CEPHFS_SECRET}"
type: kubernetes.io/rbd
data:
  key: $( echo ${ENCODED_KEYRING} )
EOF
  kubectl apply --namespace ${NAMESPACE} -f ${SECRET}

fi

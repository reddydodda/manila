## Pre-Requisite 

1. Deploy MOSK ( https://docs.mirantis.com/mosk/latest/deploy/deploy-openstack.html )
2. update osdpl to create rabitmq users for manila 

```shell
  services:
    messaging:
      rabbitmq:
        values:
          conf:
            aux_conf:
              policies:
              - definition:
                  message-ttl: 120000
                name: default-policy-manila
                pattern: ^(?!amq\.).*
                vhost: manila
              - definition:
                  expires: 3600000
                name: results_expire_manila
                pattern: ^results\.
                priority: 1
                vhost: manila
              - definition:
                  expires: 3600000
                name: tasks_expire_manila
                pattern: ^tasks\.
                priority: 1
                vhost: manila
            users:
              manila_service:
                auth:
                  manila:
                    password: password
                    username: manila
                path: /manila
              manila_service_notifications:
                auth:
                  manila:
                    password: password
                    username: manila
                path: /openstack

```
3. update manila values 

`endpoints:oslo_db:admin:username`  && `endpoints:oslo_db:admin:password`

 ```shell
 kubectl -n openstack get secrets openstack-admin-users -ojsonpath='{.data.database}' | base64 -d | jq -r '.username'
 root

 kubectl -n openstack get secrets openstack-admin-users -ojsonpath='{.data.database}' | base64 -d | jq -r '.password'
 MII9NdjIVdfRs1XEmb3yKCyvmsC5GQM9
 ```

`endpoints:oslo_messaging:admin:username`  & `endpoints:oslo_messaging:admin:password`

 ```shell
 kubectl -n openstack get secrets openstack-admin-users -ojsonpath='{.data.messaging}' | base64 -d | jq -r '.username'
 rabbitmq

 kubectl -n openstack get secrets openstack-admin-users -ojsonpath='{.data.messaging}' | base64 -d | jq -r '.password'
 QEgx8HNQz57Z7trLYdUjGp3ZsKwkBsz6
 ```

`endpoints:identity:auth:admin:username`  & `endpoints:identity:auth:admin:password`

 ```shell
 kubectl -n openstack get secrets openstack-admin-users -ojsonpath='{.data.identity}' | base64 -d | jq -r '.username'
 admin

 kubectl -n openstack get secrets openstack-admin-users -ojsonpath='{.data.identity}' | base64 -d | jq -r '.password'
 d7GPSxejMjcsbAXu0aUEMBT6kCbsaKn6
 ```



`endpoints:identity:auth:nova:username` && `endpoints:identity:auth:nova:password` 

 ```shell
 kubectl -n openstack get secrets nova-keystone-user -ojsonpath='{.data.OS_USERNAME}' | base64 -d
 kubectl -n openstack get secrets nova-keystone-user -ojsonpath='{.data.OS_PASSWORD}' | base64 -d
 ```

`endpoints:identity:auth:neutron:username` && `endpoints:identity:auth:neutron:password` 

 ```shell
 kubectl -n openstack get secrets neutron-keystone-user -ojsonpath='{.data.OS_USERNAME}' | base64 -d
 kubectl -n openstack get secrets neutron-keystone-user -ojsonpath='{.data.OS_PASSWORD}' | base64 -d
 ```

`endpoints:identity:auth:cinder:username` && `endpoints:identity:auth:cinder:password` 

 ```shell
 kubectl -n openstack get secrets cinder-keystone-user -ojsonpath='{.data.OS_USERNAME}' | base64 -d
 kubectl -n openstack get secrets cinder-keystone-user -ojsonpath='{.data.OS_PASSWORD}' | base64 -d
 ```

`endpoints:identity:auth:glance:username` && `endpoints:identity:auth:glance:password` 

 ```shell
 kubectl -n openstack get secrets glance-keystone-user -ojsonpath='{.data.OS_USERNAME}' | base64 -d
 kubectl -n openstack get secrets glance-keystone-user -ojsonpath='{.data.OS_PASSWORD}' | base64 -d
 ```



4. update NetApp configs 

```shell
conf:
  backends:
    [cdotMultipleSVM]
    share_backend_name=cdotMultipleSVM
    share_driver=manila.share.drivers.netapp.common.NetAppDriver
    driver_handles_share_servers=True
    netapp_storage_family=ontap_cluster
    netapp_server_hostname=hostname
    netapp_server_port=80
    netapp_login=admin_username
    netapp_password=admin_password
    netapp_transport_type=https
    netapp_root_volume_aggregate=aggr1
    netapp_aggregate_name_search_pattern=^((?!aggr0).)*$

```

5. copy helm charts to openstack-controller

`kubectl cp manila/ osh-system/openstack-controller-5d96cc84db-s5t7d:/root/ -c osdpl`

6. install helm chart by loginign to openstack-controller

```shell
helm3 upgrade --install openstack-manila ./manila --namespace=openstack --values=manila/values_override.yaml

helm3 get values -n openstack openstack-manila
```




####################
Debug
####################

apt update; apt install vim strace -y

vim /var/lib/kolla/venv/lib/python3.8/site-packages/manila/share/manager.py

316

import pdb
pdb.set_trace()

manila-share --config-file /etc/manila/manila.conf --config-file /etc/manila/conf/backends.conf



ovs-vsctl --no-wait show


##################


manila --endpoint-type internal type-create default_share_type false



#################
LVM
###############

sudo apt-get install lvm2 nfs-kernel-server vim -y


sudo pvcreate /dev/vdd
sudo vgcreate manila-volumes /dev/vdd



filter = [ "a/vda/", "a/vdb/", "a/vdc/", "a/vdd/", "r/.*/"]




#################

https://gerrit.mcp.mirantis.com/c/kaas/core/+/127791/2/bootstrap/releases/cluster/8.7.0-rc.yaml

kubectl -n ceph-lcm-mirantis edit deploy ceph-controller
change image to: 127.0.0.1:44301/ceph/mcp/ceph-controller:v1.0.0-20220401131257

#################

exec manila-scheduler --config-file /etc/manila/manila.conf


####################

curl -L https://tarballs.opendev.org/openstack/manila-image-elements/images/manila-service-image-master.qcow2 | glance image-create --name "manila-service-image" --disk-format qcow2 --container-format bare --visibility public --progress


######################



manila --endpoint-type internal share-network-create --name manila-share-network1 --neutron-net-id 34747ff1-c591-4ba9-9ad2-2a53c89e1032 --neutron-subnet-id 4704ea87-5ecf-4eaa-ab0d-4758832b2e19



######################


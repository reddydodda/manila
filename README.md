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


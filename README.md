helm3 upgrade --install openstack-manila ./manila --namespace=openstack --values=manila/values_override.yaml

helm3 get values -n openstack openstack-manila


helm3 delete openstack-manila -n openstack


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

###################
get passwords
###################
 

kubectl -n openstack get secrets openstack-admin-users -ojsonpath='{.data.database}' | base64 -d | jq -r '.username'
root

kubectl -n openstack get secrets openstack-admin-users -ojsonpath='{.data.database}' | base64 -d | jq -r '.password'
MII9NdjIVdfRs1XEmb3yKCyvmsC5GQM9

kubectl -n openstack get secrets openstack-admin-users -ojsonpath='{.data.identity}' | base64 -d | jq -r '.username'
admin

kubectl -n openstack get secrets openstack-admin-users -ojsonpath='{.data.identity}' | base64 -d | jq -r '.password'
d7GPSxejMjcsbAXu0aUEMBT6kCbsaKn6

kubectl -n openstack get secrets openstack-admin-users -ojsonpath='{.data.messaging}' | base64 -d | jq -r '.username'
rabbitmq

kubectl -n openstack get secrets openstack-admin-users -ojsonpath='{.data.messaging}' | base64 -d | jq -r '.password'
QEgx8HNQz57Z7trLYdUjGp3ZsKwkBsz6





#Nova

kubectl -n openstack get secrets nova-keystone-user -ojsonpath='{.data.OS_USERNAME}' | base64 -d
kubectl -n openstack get secrets nova-keystone-user -ojsonpath='{.data.OS_PASSWORD}' | base64 -d


#Neutron

kubectl -n openstack get secrets neutron-keystone-user -ojsonpath='{.data.OS_USERNAME}' | base64 -d
kubectl -n openstack get secrets neutron-keystone-user -ojsonpath='{.data.OS_PASSWORD}' | base64 -d


#Cinder

kubectl -n openstack get secrets cinder-keystone-user -ojsonpath='{.data.OS_USERNAME}' | base64 -d
kubectl -n openstack get secrets cinder-keystone-user -ojsonpath='{.data.OS_PASSWORD}' | base64 -d

#Glance

kubectl -n openstack get secrets glance-keystone-user -ojsonpath='{.data.OS_USERNAME}' | base64 -d
kubectl -n openstack get secrets glance-keystone-user -ojsonpath='{.data.OS_PASSWORD}' | base64 -d





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
# change image to: 127.0.0.1:44301/ceph/mcp/ceph-controller:v1.0.0-20220401131257

#################

exec manila-scheduler --config-file /etc/manila/manila.conf


####################

curl -L https://tarballs.opendev.org/openstack/manila-image-elements/images/manila-service-image-master.qcow2 | glance image-create --name "manila-service-image" --disk-format qcow2 --container-format bare --visibility public --progress


######################



manila --endpoint-type internal share-network-create --name manila-share-network1 --neutron-net-id 34747ff1-c591-4ba9-9ad2-2a53c89e1032 --neutron-subnet-id 4704ea87-5ecf-4eaa-ab0d-4758832b2e19



######################


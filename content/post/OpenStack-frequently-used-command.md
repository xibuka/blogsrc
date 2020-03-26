---
title: OpenStack frequently used command
date: 2018-09-27 22:09:02
tags:
- OpenStack
- Cloud
---
# OpenStack frequently used command

## OpenStack Compute - Nova

* list instances
`nova list` 
`openstack server list` 
* list/check flavor
`nova flavor-list`
`nova flavor-show <name or ID>`
`openstack flavor list`
`openstack flavor show <name or ID>` 
* create flavor
`openstack flavor create --ram <ram> --vcpus <cpu number> --disk <size> --id <id> <name>`
`nova flavor-create <name> <id> <ram> <disk> <vcpus>`
* launch an instance
`nova boot <name> --image <image> --flavor <flavor>`
`openstack server create --flavor <flavor> --image <image> <name>`
* launch an instance with network
`openstack server create --flavor <flavor> --image <image> <name> net-id=<network>`
* launch an instance with key-pair
`nova boot <name> --image <image> --flavor <flavor> --key-name <key-pair name>`
`openstack server create --flavor <flavor> --image <image> <name>`
* access instance via router
`ip netns list`
`sudo ip netns exec <qrouter-id> ssh -i <key> user@ip` 
* launch an instance with custom port
`nova boot --image <image> --flavor <flavor> --nic port-id=<port-id> <instance name>`
* delete an instance
`nova delete <ID>`
`openstack server delete <ID or name>`

<!-- more -->

## Openstack Network - Neutron
* list network
`openstack network list`
* list subnetwork
`openstack subnet list --long`
* create a network
`openstack network create <net name>`
* create a subnetwork
`openstack subnet create <subnet name> --network <net name> --subnet-range <ip address>/<prefix> --gateway <gw ip> --allocation-pool start=IP_ADDR,end=IP_ADDR` 
e.g. 
`openstack subnet create practicesubnet --network practice --subnet-range 10.2.0.224/27 --gateway 10.2.0.225 --allocation-pool start=10.2.0.240,end=10.2.0.245`
* create port with specify IP address
`openstack subnet list --long` to confirm avaiable address range
`openstack port create --network=<network> 
  --fixed-ip subnet=private-subnet,ip-address=<ip_address> <port name>`
* create port without specify IP address
`openstack port create <port name> --network <network>`
system will allocate one IP address for this port
* search ports with specified fixed IP addresses
`neutron port-list --fixed-ips ip_address=<IP1> ip_address=<IP2>`
* create a router
`openstack router create <router>`
* Link the router to the external provider network
`openstack router set <router> --external-gateway <public network>`
* add subnet to router
`openstack router add subnet <router> <subnet>`
* remove subnet from router
`openstack router remove subnet <router> <subnet>`
* delete router
`openstack router delete <router>`
* create external network
`openstack network create public --external --provider-network-type flat --provider-physical-network external`
* manage floating IP
`neutron floatingip-create      `   
`neutron floatingip-delete      `
`neutron floatingip-associate   `
`neutron floatingip-disassociate`
`neutron floatingip-list        `

e.g.
`neutron floatingip-create public`
`neutron floatingip-associate <fip ID> <port ID of instance's internal ip>`

## OpenStack Image - Glance
* image list and show detail
`glance image-list`
`glance image-show <ID>`
`openstack image list`
`openstack image show <name or ID>`
* check image file info
`qemu-img info <path/to/image>`
* create image from file
`glance image-create --progress --name <name> --file /path/to/file --disk-format qcow2 --container-format bare --visibility public`
* download image
`openstack image save <image> --file <save/to/file>`
* delete an image
`glance image-delete <ID>`
`openstack image delete <ID>`

## OpenStack block Storage - Cinder
* volume list and show detail
`cinder list`
`cinder show <ID>`
`openstack volume list`
`openstack volume show <name or ID>`
* create new empty volume
`cinder create --name <vol name> <size in GiBs>`
* create new volume from image
`cinder create --name <vol name> <size in GiBs> --image <ID or Name>` 
* attach volume to an instance
`openstack server add volume <instance> <volume>`
`nova volume-attach <instance> <volume ID> <device>`
* detach volume from an instance
`openstack server remove volume <instance> <volume>`
`nova volume-detach <server> <volume>`
* delete volume
`cinder delete <volume>`
`openstack volume delete <volume>`

## OpenStack Identity - Keystone
* issue a token
`openstack token issue`
* check auth info
`source credrc.sh` which the file looks like

```
export OS_AUTH_TYPE=password
export OS_AUTH_URL=http://127.0.0.1:5000/v3
export OS_IDENTITY_API_VERSION="3"
export OS_TENANT_NAME="demo"
export OS_USERNAME="demo"
export OS_PASSWORD="nova"
export OS_PROJECT_DOMAIN_ID="default"
export OS_USER_DOMAIN_ID="default"
export OS_REGION_NAME="RegionOne"
alias osc="openstack --os-cloud"
```

* check auth info with 
`export | grep OS_` 
* create new project
`openstack project create --description "text" <project name>`
* create and delete user
`openstack user create <name> --password pass`
`openstack user delete <name>`
* check role list
`openstack role list`
* change user's role in project
`openstack role add --user <user> --project <project> <role>`
* show quota of a project
`openstack quota show <project id>`
`nova quota-show --tenant <project id>`
* update quota of a project
`openstack quota set --<key> <value> <project id>`
`nova quota-update --<key> <value> <project id>`
* change policy

```
vim /etc/glance/policy.json
...
    "add_image": "role:admin",
...
```

* key pair create and list
`nova keypair-add <name> --pub-key <path/to/public/key>`
`openstack keypair create <name> --pub-key <path/to/public/key>`
`nova keypair-list`
* add security group rule to allow SSH access
`openstack security group rule create <rule name> --ingress --dst-port 22:22 --protocol tcp --remote-ip 0.0.0.0/0 <group name>`
`nova secgroup-add-rule <group name> <ip-proto> <from-port> <to-port>`
`e.g. nova secgroup-add-rule novasg2 tcp 22 22 0.0.0.0/24`
* list security group and rule
`openstack security group list`
`openstack security group rule list`


## OpenStack Object Storage - Swift
The account is not the user account, but more like a namespace/project in swift.
The container is like the directory.

|Task|Command|
|---|---|
|Get account info   |`swift stat`|
|create a container	|`swift post <container>`|
|list all containers in an account|`swift list`|
|get the info of a container |`swift stat <container>`|
|upload files/directory to a container|`swift upload --object-name <object> <containe> <file/firectory path> `|
|list files in a container |`swift list <containe>`|
|download file | `swift download <container> <object>`|
|update meta data to container |`swift post --meta <color>:<value> <container>`|
|delete object|	`swift delete <container> <object>`|
|upload files in specify segments| `swift upload <container> <object> --segment-size <size>`|
|delete container| `swift delete <container>`|

e.g.
`swift upload uploads files/puppies.jpg --object-name picture`
1. adding a read ACL on the uploads container allowing anyone to read it except for people from gadget.example.com.
`swift post -r .r:*,-gadget.example.com uploads`
1. adding a write ACL to the uploads container allowing anyone in the phone project to write to it.
`swift post -w phone:* uploads`

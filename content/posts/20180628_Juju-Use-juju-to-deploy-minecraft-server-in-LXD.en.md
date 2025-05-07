---
title: '[Juju] Use juju to deploy minecraft server in LXD'
date: 2018-06-28 17:01:36
tags:
- Ubuntu
- Juju
---

Juju is a deploy tool which supports a very wide range of cloud providers,
like AWS, Azure, Google Cloud Platform, MAAS and LXD. This artcle will focus on
how to build an OpenStack test environment using Juju and LXD.

## installing LXD

It is very easy to install LXD, just run below command

```bash
sudo apt-install lxd
```

If you can't find lxd package, run below command to add PPA(Personal Package
Archive) to find LXD package. Then re-run the install command.

```bash
sudo apt-add-repository ppa:ubuntu-lxc/stable
sudo apt update
sudo apt dist-upgrade
```

## Configuring LXD

Run below command to config lxd setting step by step

```bash
$ sudo lxd init
Do you want to configure a new storage pool (yes/no) [default=yes]?
Name of the storage backend to use (dir or zfs) [default=dir]:
Would you like LXD to be available over the network (yes/no) [default=no]?
Do you want to configure the LXD bridge (yes/no) [default=yes]?
Warning: Stopping lxd.service, but it can still be activated by:
  lxd.socket
LXD has been successfully configured.
```

## Installing juju

Run below command to install juju

```bash
$ sudo apt install juju
Reading package lists... Done
Building dependency tree
Reading state information... Done
The following additional packages will be installed:
  distro-info juju-2.0
Suggested packages:
  shunit2 juju-core
The following NEW packages will be installed:
  distro-info juju juju-2.0
0 upgraded, 3 newly installed, 0 to remove and 0 not upgraded.
Need to get 32.0 MB of archives.
After this operation, 168 MB of additional disk space will be used.
Do you want to continue? [Y/n]
Get:1 http://archive.ubuntu.com/ubuntu xenial/main amd64 distro-info amd64 0.14build1 [20.0 kB]
Get:2 http://archive.ubuntu.com/ubuntu xenial-updates/main amd64 juju-2.0 amd64 2.3.7-0ubuntu0.16.04.1 [32.0 MB]
Get:3 http://archive.ubuntu.com/ubuntu xenial-updates/main amd64 juju all 2.3.7-0ubuntu0.16.04.1 [10.2 kB]
Fetched 32.0 MB in 4s (6,778 kB/s)
Preconfiguring packages ...
Selecting previously unselected package distro-info.
(Reading database ... 60478 files and directories currently installed.)
Preparing to unpack .../distro-info_0.14build1_amd64.deb ...
Unpacking distro-info (0.14build1) ...
Selecting previously unselected package juju-2.0.
Preparing to unpack .../juju-2.0_2.3.7-0ubuntu0.16.04.1_amd64.deb ...
Unpacking juju-2.0 (2.3.7-0ubuntu0.16.04.1) ...
Selecting previously unselected package juju.
Preparing to unpack .../juju_2.3.7-0ubuntu0.16.04.1_all.deb ...
Unpacking juju (2.3.7-0ubuntu0.16.04.1) ...
Processing triggers for man-db (2.7.5-1) ...
Setting up distro-info (0.14build1) ...
Setting up juju-2.0 (2.3.7-0ubuntu0.16.04.1) ...
Setting up juju (2.3.7-0ubuntu0.16.04.1) ...
```

Once the install is done, we can bootstrap a new controller using LXD. This
means that juju will create a new LXD container for management service.

We can create a controller called juju-controller with below command

```bash
$ juju bootstrap localhost juju-controller
Since Juju 2 is being run for the first time, downloading latest cloud information.
Fetching latest public cloud list...
Your list of public clouds is up to date, see `juju clouds`.
Creating Juju controller "juju-controller" on localhost/localhost
Looking for packaged Juju agent version 2.3.7 for amd64
To configure your system to better support LXD containers, please see: https://github.com/lxc/lxd/blob/master/doc/production-setup.md
Launching controller instance(s) on localhost/localhost...
 - juju-9ccefc-0 (arch=amd64)                                                                                   s)
Installing Juju agent on bootstrap instance
Fetching Juju GUI 2.12.3
Waiting for address
Attempting to connect to 10.229.139.129:22
Connected to 10.229.139.129
Running machine configuration script...
Bootstrap agent now started
Contacting Juju controller at 10.229.139.129 to verify accessibility...
Bootstrap complete, "juju-controller" controller now available
Controller machines are in the "controller" model
Initial model "default" added
```

After this, we can see a new LXD container is running.

```bash
$ lxc list
+---------------+---------+-----------------------+------+------------+-----------+
|     NAME      |  STATE  |         IPV4          | IPV6 |    TYPE    | SNAPSHOTS |
+---------------+---------+-----------------------+------+------------+-----------+
| juju-9ccefc-0 | RUNNING | 10.229.139.129 (eth0) |      | PERSISTENT | 0         |
+---------------+---------+-----------------------+------+------------+-----------+
```

And run `juju status` to check there is nothing running yet.

```bash
$ juju status
Model    Controller       Cloud/Region         Version  SLA
default  juju-controller  localhost/localhost  2.3.7    unsupported

App  Version  Status  Scale  Charm  Store  Rev  OS  Notes

Unit  Workload  Agent  Machine  Public address  Ports  Message

Machine  State  DNS  Inst id  Series  AZ  Message

```

## Deploy minecraft server

OK, now we are ready for deploy minecraft server!
Run below command to tell juju you want to deploy it. and it should return
immediately. However it doesn't mean the service is ready. Run `juju status` to
check the status.

```bash
$ juju status
Model    Controller       Cloud/Region         Version  SLA
default  juju-controller  localhost/localhost  2.3.7    unsupported

App        Version  Status   Scale  Charm      Store       Rev  OS      Notes
minecraft           waiting    0/1  minecraft  jujucharms    3  ubuntu  

Unit         Workload  Agent       Machine  Public address  Ports  Message
minecraft/0  waiting   allocating  0        10.229.139.124         waiting for machine

Machine  State    DNS             Inst id        Series  AZ  Message
0        pending  10.229.139.124  juju-72dd35-0  trusty      Running
```

From above we can see juju is working on creating the server. And we also can
check a new container is created for minecraft server, by `lxc list` command.

```bash
$ lxc list
+---------------+---------+-----------------------+------+------------+-----------+
|     NAME      |  STATE  |         IPV4          | IPV6 |    TYPE    | SNAPSHOTS |
+---------------+---------+-----------------------+------+------------+-----------+
| juju-72dd35-0 | RUNNING | 10.229.139.124 (eth0) |      | PERSISTENT | 0         |
+---------------+---------+-----------------------+------+------------+-----------+
| juju-9ccefc-0 | RUNNING | 10.229.139.129 (eth0) |      | PERSISTENT | 0         |
+---------------+---------+-----------------------+------+------------+-----------+
```

After a while, the deploying is done and the service is active.

```bash
$ juju status
Model    Controller       Cloud/Region         Version  SLA
default  juju-controller  localhost/localhost  2.3.7    unsupported

App        Version  Status  Scale  Charm      Store       Rev  OS      Notes
minecraft           active      1  minecraft  jujucharms    3  ubuntu  

Unit          Workload  Agent  Machine  Public address  Ports      Message
minecraft/0*  active    idle   0        10.229.139.124  25565/tcp  Ready

Machine  State    DNS             Inst id        Series  AZ  Message
0        started  10.229.139.124  juju-72dd35-0  trusty      Running
```

Now you can start your minecraft client, and point to 10.229.139.124 on port
25565 to play with your all new minecraft server!

If you want to get rid of it, just run below command.
Every service or server related to minecraft server will be gone.

```bash
juju destroy-service minecraft
```

You can also destory juju controller and all service/server created by it.
The easiest way to destory everything is as below.

```bash
$ juju destroy-controller juju-controller --destroy-all-models
WARNING! This command will destroy the "juju-controller" controller.
This includes all machines, applications, data and other resources.

Continue? (y/N):y
Destroying controller
Waiting for hosted model resources to be reclaimed
Waiting on 1 model, 1 machine, 1 application
Waiting on 1 model, 1 machine, 1 application
Waiting on 1 model, 1 machine
All hosted models reclaimed, cleaning up controller machines
```

We can confirm that all containers are gone.

```bash
$ lxc list
+------+-------+------+------+------+-----------+
| NAME | STATE | IPV4 | IPV6 | TYPE | SNAPSHOTS |
+------+-------+------+------+------+-----------+
```

## Deploy OpenStack

You can deploy a more complicated environment such as OpenStack using Juju.

```bash
$ juju deploy cs:bundle/openstack-base-55
Located bundle "cs:bundle/openstack-base-55"
Resolving charm: cs:ceph-mon-25
Resolving charm: cs:ceph-osd-262
Resolving charm: cs:ceph-radosgw-258
Resolving charm: cs:cinder-272
Resolving charm: cs:cinder-ceph-233
Resolving charm: cs:glance-265
Resolving charm: cs:keystone-281
Resolving charm: cs:percona-cluster-266
Resolving charm: cs:neutron-api-260
Resolving charm: cs:neutron-gateway-252
Resolving charm: cs:neutron-openvswitch-250
Resolving charm: cs:nova-cloud-controller-310
Resolving charm: cs:nova-compute-284
Resolving charm: cs:ntp-24
Resolving charm: cs:openstack-dashboard-259
Resolving charm: cs:rabbitmq-server-74
Executing changes:
- upload charm cs:ceph-mon-25 for series bionic
- deploy application ceph-mon on bionic using cs:ceph-mon-25
- set annotations for ceph-mon
- upload charm cs:ceph-osd-262 for series bionic
- deploy application ceph-osd on bionic using cs:ceph-osd-262
- set annotations for ceph-osd
- upload charm cs:ceph-radosgw-258 for series bionic
- deploy application ceph-radosgw on bionic using cs:ceph-radosgw-258
- set annotations for ceph-radosgw
- upload charm cs:cinder-272 for series bionic
- deploy application cinder on bionic using cs:cinder-272
- set annotations for cinder
- upload charm cs:cinder-ceph-233 for series bionic
- deploy application cinder-ceph on bionic using cs:cinder-ceph-233
- set annotations for cinder-ceph
- upload charm cs:glance-265 for series bionic
- deploy application glance on bionic using cs:glance-265
- set annotations for glance
- upload charm cs:keystone-281 for series bionic
- deploy application keystone on bionic using cs:keystone-281
- set annotations for keystone
- upload charm cs:percona-cluster-266 for series bionic
- deploy application mysql on bionic using cs:percona-cluster-266
- set annotations for mysql
- upload charm cs:neutron-api-260 for series bionic
- deploy application neutron-api on bionic using cs:neutron-api-260
- set annotations for neutron-api
- upload charm cs:neutron-gateway-252 for series bionic
- deploy application neutron-gateway on bionic using cs:neutron-gateway-252
- set annotations for neutron-gateway
- upload charm cs:neutron-openvswitch-250 for series bionic
- deploy application neutron-openvswitch on bionic using cs:neutron-openvswitch-250
- set annotations for neutron-openvswitch
- upload charm cs:nova-cloud-controller-310 for series bionic
- deploy application nova-cloud-controller on bionic using cs:nova-cloud-controller-310
- set annotations for nova-cloud-controller
- upload charm cs:nova-compute-284 for series bionic
- deploy application nova-compute on bionic using cs:nova-compute-284
- set annotations for nova-compute
- upload charm cs:ntp-24 for series bionic
- deploy application ntp on bionic using cs:ntp-24
- set annotations for ntp
- upload charm cs:openstack-dashboard-259 for series bionic
- deploy application openstack-dashboard on bionic using cs:openstack-dashboard-259
- set annotations for openstack-dashboard
- upload charm cs:rabbitmq-server-74 for series bionic
- deploy application rabbitmq-server on bionic using cs:rabbitmq-server-74
- set annotations for rabbitmq-server
- add new machine 0
- add new machine 1
- add new machine 2
- add new machine 3
- add relation nova-compute:amqp - rabbitmq-server:amqp
- add relation neutron-gateway:amqp - rabbitmq-server:amqp
- add relation keystone:shared-db - mysql:shared-db
- add relation nova-cloud-controller:identity-service - keystone:identity-service
- add relation glance:identity-service - keystone:identity-service
- add relation neutron-api:identity-service - keystone:identity-service
- add relation neutron-openvswitch:neutron-plugin-api - neutron-api:neutron-plugin-api
- add relation neutron-api:shared-db - mysql:shared-db
- add relation neutron-api:amqp - rabbitmq-server:amqp
- add relation neutron-gateway:neutron-plugin-api - neutron-api:neutron-plugin-api
- add relation glance:shared-db - mysql:shared-db
- add relation glance:amqp - rabbitmq-server:amqp
- add relation nova-cloud-controller:image-service - glance:image-service
- add relation nova-compute:image-service - glance:image-service
- add relation nova-cloud-controller:cloud-compute - nova-compute:cloud-compute
- add relation nova-cloud-controller:amqp - rabbitmq-server:amqp
- add relation nova-cloud-controller:quantum-network-service - neutron-gateway:quantum-network-service
- add relation nova-compute:neutron-plugin - neutron-openvswitch:neutron-plugin
- add relation neutron-openvswitch:amqp - rabbitmq-server:amqp
- add relation openstack-dashboard:identity-service - keystone:identity-service
- add relation nova-cloud-controller:shared-db - mysql:shared-db
- add relation nova-cloud-controller:neutron-api - neutron-api:neutron-api
- add relation cinder:image-service - glance:image-service
- add relation cinder:amqp - rabbitmq-server:amqp
- add relation cinder:identity-service - keystone:identity-service
- add relation cinder:cinder-volume-service - nova-cloud-controller:cinder-volume-service
- add relation cinder-ceph:storage-backend - cinder:storage-backend
- add relation ceph-mon:client - nova-compute:ceph
- add relation nova-compute:ceph-access - cinder-ceph:ceph-access
- add relation cinder:shared-db - mysql:shared-db
- add relation ceph-mon:client - cinder-ceph:ceph
- add relation ceph-mon:client - glance:ceph
- add relation ceph-osd:mon - ceph-mon:osd
- add relation ntp:juju-info - nova-compute:juju-info
- add relation ntp:juju-info - neutron-gateway:juju-info
- add relation ceph-radosgw:mon - ceph-mon:radosgw
- add relation ceph-radosgw:identity-service - keystone:identity-service
- add unit ceph-osd/0 to new machine 1
- add unit ceph-osd/1 to new machine 2
- add unit ceph-osd/2 to new machine 3
- add unit neutron-gateway/0 to new machine 0
- add unit nova-compute/0 to new machine 1
- add unit nova-compute/1 to new machine 2
- add unit nova-compute/2 to new machine 3
- add lxd container 1/lxd/0 on new machine 1
- add lxd container 2/lxd/0 on new machine 2
- add lxd container 3/lxd/0 on new machine 3
- add lxd container 0/lxd/0 on new machine 0
- add lxd container 1/lxd/1 on new machine 1
- add lxd container 2/lxd/1 on new machine 2
- add lxd container 3/lxd/1 on new machine 3
- add lxd container 0/lxd/1 on new machine 0
- add lxd container 1/lxd/2 on new machine 1
- add lxd container 2/lxd/2 on new machine 2
- add lxd container 3/lxd/2 on new machine 3
- add lxd container 0/lxd/2 on new machine 0
- add unit ceph-mon/0 to 1/lxd/0
- add unit ceph-mon/1 to 2/lxd/0
- add unit ceph-mon/2 to 3/lxd/0
- add unit ceph-radosgw/0 to 0/lxd/0
- add unit cinder/0 to 1/lxd/1
- add unit glance/0 to 2/lxd/1
- add unit keystone/0 to 3/lxd/1
- add unit mysql/0 to 0/lxd/1
- add unit neutron-api/0 to 1/lxd/2
- add unit nova-cloud-controller/0 to 2/lxd/2
- add unit openstack-dashboard/0 to 3/lxd/2
- add unit rabbitmq-server/0 to 0/lxd/2
Deploy of bundle completed.
```

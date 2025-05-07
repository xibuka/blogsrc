---
title: OpenStack 常用命令
date: 2018-09-27 22:09:02
tags:
- OpenStack
- Cloud
---
## OpenStack 常用命令

### OpenStack Compute - Nova

* 列出实例
`nova list`
`openstack server list`
* 列出/查看 flavor
`nova flavor-list`
`nova flavor-show <name or ID>`
`openstack flavor list`
`openstack flavor show <name or ID>`
* 创建 flavor
`openstack flavor create --ram <ram> --vcpus <cpu number> --disk <size> --id <id> <name>`
`nova flavor-create <name> <id> <ram> <disk> <vcpus>`
* 启动实例
`nova boot <name> --image <image> --flavor <flavor>`
`openstack server create --flavor <flavor> --image <image> <name>`
* 指定网络启动实例
`openstack server create --flavor <flavor> --image <image> <name> net-id=<network>`
* 指定密钥对启动实例
`nova boot <name> --image <image> --flavor <flavor> --key-name <key-pair name>`
`openstack server create --flavor <flavor> --image <image> <name>`
* 通过路由器访问实例
`ip netns list`
`sudo ip netns exec <qrouter-id> ssh -i <key> user@ip`
* 使用自定义端口启动实例
`nova boot --image <image> --flavor <flavor> --nic port-id=<port-id> <instance name>`
* 删除实例
`nova delete <ID>`
`openstack server delete <ID or name>`

### Openstack Network - Neutron

* 列出网络
`openstack network list`
* 列出子网
`openstack subnet list --long`
* 创建网络
`openstack network create <net name>`
* 创建子网
`openstack subnet create <subnet name> --network <net name> --subnet-range <ip address>/<prefix> --gateway <gw ip> --allocation-pool start=IP_ADDR,end=IP_ADDR`
例如：
`openstack subnet create practicesubnet --network practice --subnet-range 10.2.0.224/27 --gateway 10.2.0.225 --allocation-pool start=10.2.0.240,end=10.2.0.245`
* 指定 IP 地址创建端口
`openstack subnet list --long` 查看可用地址范围
`openstack port create --network=<network>
  --fixed-ip subnet=private-subnet,ip-address=<ip_address> <port name>`
* 不指定 IP 地址创建端口
`openstack port create <port name> --network <network>`
系统会自动分配一个 IP 地址
* 按固定 IP 查询端口
`neutron port-list --fixed-ips ip_address=<IP1> ip_address=<IP2>`
* 创建路由器
`openstack router create <router>`
* 路由器连接外部网络
`openstack router set <router> --external-gateway <public network>`
* 向路由器添加子网
`openstack router add subnet <router> <subnet>`
* 从路由器移除子网
`openstack router remove subnet <router> <subnet>`
* 删除路由器
`openstack router delete <router>`
* 创建外部网络
`openstack network create public --external --provider-network-type flat --provider-physical-network external`
* Floating IP 管理
`neutron floatingip-create`
`neutron floatingip-delete`
`neutron floatingip-associate`
`neutron floatingip-disassociate`
`neutron floatingip-list`

例如：
`neutron floatingip-create public`
`neutron floatingip-associate <fip ID> <port ID of instance's internal ip>`

### OpenStack Image - Glance

* 列出/查看镜像
`glance image-list`
`glance image-show <ID>`
`openstack image list`
`openstack image show <name or ID>`
* 查看镜像文件信息
`qemu-img info <path/to/image>`
* 从文件创建镜像
`glance image-create --progress --name <name> --file /path/to/file --disk-format qcow2 --container-format bare --visibility public`
* 下载镜像
`openstack image save <image> --file <save/to/file>`
* 删除镜像
`glance image-delete <ID>`
`openstack image delete <ID>`

### OpenStack 块存储 - Cinder

* 列出/查看卷
`cinder list`
`cinder show <ID>`
`openstack volume list`
`openstack volume show <name or ID>`
* 创建新空卷
`cinder create --name <vol name> <size in GiBs>`
* 从镜像创建新卷
`cinder create --name <vol name> <size in GiBs> --image <ID or Name>`
* 挂载卷到实例
`openstack server add volume <instance> <volume>`
`nova volume-attach <instance> <volume ID> <device>`
* 从实例卸载卷
`openstack server remove volume <instance> <volume>`
`nova volume-detach <server> <volume>`
* 删除卷
`cinder delete <volume>`
`openstack volume delete <volume>`

### OpenStack 身份认证 - Keystone

* 获取 token
`openstack token issue`
* 查看认证信息
`source credrc.sh` 文件示例：

```sh
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

* 查看认证信息
`export | grep OS_`
* 创建项目
`openstack project create --description "text" <project name>`
* 创建/删除用户
`openstack user create <name> --password pass`
`openstack user delete <name>`
* 查看角色列表
`openstack role list`
* 修改项目中用户的角色
`openstack role add --user <user> --project <project> <role>`
* 查看项目配额
`openstack quota show <project id>`
`nova quota-show --tenant <project id>`
* 更新项目配额
`openstack quota set --<key> <value> <project id>`
`nova quota-update --<key> <value> <project id>`
* 修改策略

```sh
vim /etc/glance/policy.json
...
    "add_image": "role:admin",
...
```

* 创建/列出密钥对
`nova keypair-add <name> --pub-key <path/to/public/key>`
`openstack keypair create <name> --pub-key <path/to/public/key>`
`nova keypair-list`
* 给安全组添加 SSH 规则
`openstack security group rule create <rule name> --ingress --dst-port 22:22 --protocol tcp --remote-ip 0.0.0.0/0 <group name>`
`nova secgroup-add-rule <group name> <ip-proto> <from-port> <to-port>`
`例如: nova secgroup-add-rule novasg2 tcp 22 22 0.0.0.0/24`
* 列出安全组和规则
`openstack security group list`
`openstack security group rule list`

### OpenStack 对象存储 - Swift

Account 不是用户账号，更像是 swift 里的命名空间/项目。
Container 类似于目录。

|任务|命令|
|---|---|
|获取账号信息   |`swift stat`|
|创建 container|`swift post <container>`|
|列出账号下所有 container|`swift list`|
|获取 container 信息 |`swift stat <container>`|
|上传文件/目录到 container|`swift upload --object-name <object> <containe> <file/firectory path>`|
|列出 container 内文件 |`swift list <containe>`|
|下载文件 | `swift download <container> <object>`|
|给 container 添加元数据 |`swift post --meta <color>:<value> <container>`|
|删除对象|`swift delete <container> <object>`|
|分段上传文件| `swift upload <container> <object> --segment-size <size>`|
|删除 container| `swift delete <container>`|

例如：
`swift upload uploads files/puppies.jpg --object-name picture`

1. 给 uploads container 添加 ACL，允许除 gadget.example.com 外的任何人读取
`swift post -r .r:*,-gadget.example.com uploads`
1. 给 uploads container 添加写 ACL，允许 phone 项目下的任何人写入
`swift post -w phone:* uploads`

---
title: OpenStackでよく使うコマンド
date: 2018-09-27 22:09:02
tags:
- OpenStack
- Cloud
---
## OpenStackでよく使うコマンド

### OpenStack Compute - Nova

* インスタンス一覧
`nova list`
`openstack server list`
* フレーバー一覧・確認
`nova flavor-list`
`nova flavor-show <name or ID>`
`openstack flavor list`
`openstack flavor show <name or ID>`
* フレーバー作成
`openstack flavor create --ram <ram> --vcpus <cpu number> --disk <size> --id <id> <name>`
`nova flavor-create <name> <id> <ram> <disk> <vcpus>`
* インスタンス起動
`nova boot <name> --image <image> --flavor <flavor>`
`openstack server create --flavor <flavor> --image <image> <name>`
* ネットワーク指定でインスタンス起動
`openstack server create --flavor <flavor> --image <image> <name> net-id=<network>`
* キーペア指定でインスタンス起動
`nova boot <name> --image <image> --flavor <flavor> --key-name <key-pair name>`
`openstack server create --flavor <flavor> --image <image> <name>`
* ルーター経由でインスタンスにアクセス
`ip netns list`
`sudo ip netns exec <qrouter-id> ssh -i <key> user@ip`
* カスタムポートでインスタンス起動
`nova boot --image <image> --flavor <flavor> --nic port-id=<port-id> <instance name>`
* インスタンス削除
`nova delete <ID>`
`openstack server delete <ID or name>`

### Openstack Network - Neutron

* ネットワーク一覧
`openstack network list`
* サブネット一覧
`openstack subnet list --long`
* ネットワーク作成
`openstack network create <net name>`
* サブネット作成
`openstack subnet create <subnet name> --network <net name> --subnet-range <ip address>/<prefix> --gateway <gw ip> --allocation-pool start=IP_ADDR,end=IP_ADDR`
例：
`openstack subnet create practicesubnet --network practice --subnet-range 10.2.0.224/27 --gateway 10.2.0.225 --allocation-pool start=10.2.0.240,end=10.2.0.245`
* IPアドレス指定でポート作成
`openstack subnet list --long` で利用可能なアドレス範囲を確認
`openstack port create --network=<network>
  --fixed-ip subnet=private-subnet,ip-address=<ip_address> <port name>`
* IPアドレス未指定でポート作成
`openstack port create <port name> --network <network>`
システムが自動でIPアドレスを割り当てます
* 固定IPでポート検索
`neutron port-list --fixed-ips ip_address=<IP1> ip_address=<IP2>`
* ルーター作成
`openstack router create <router>`
* ルーターを外部プロバイダネットワークに接続
`openstack router set <router> --external-gateway <public network>`
* サブネットをルーターに追加
`openstack router add subnet <router> <subnet>`
* サブネットをルーターから削除
`openstack router remove subnet <router> <subnet>`
* ルーター削除
`openstack router delete <router>`
* 外部ネットワーク作成
`openstack network create public --external --provider-network-type flat --provider-physical-network external`
* Floating IP管理
`neutron floatingip-create`
`neutron floatingip-delete`
`neutron floatingip-associate`
`neutron floatingip-disassociate`
`neutron floatingip-list`

例：
`neutron floatingip-create public`
`neutron floatingip-associate <fip ID> <port ID of instance's internal ip>`

### OpenStack Image - Glance

* イメージ一覧・詳細表示
`glance image-list`
`glance image-show <ID>`
`openstack image list`
`openstack image show <name or ID>`
* イメージファイル情報確認
`qemu-img info <path/to/image>`
* ファイルからイメージ作成
`glance image-create --progress --name <name> --file /path/to/file --disk-format qcow2 --container-format bare --visibility public`
* イメージダウンロード
`openstack image save <image> --file <save/to/file>`
* イメージ削除
`glance image-delete <ID>`
`openstack image delete <ID>`

### OpenStackブロックストレージ - Cinder

* ボリューム一覧・詳細表示
`cinder list`
`cinder show <ID>`
`openstack volume list`
`openstack volume show <name or ID>`
* 新規空ボリューム作成
`cinder create --name <vol name> <size in GiBs>`
* イメージから新規ボリューム作成
`cinder create --name <vol name> <size in GiBs> --image <ID or Name>`
* ボリュームをインスタンスにアタッチ
`openstack server add volume <instance> <volume>`
`nova volume-attach <instance> <volume ID> <device>`
* ボリュームをインスタンスからデタッチ
`openstack server remove volume <instance> <volume>`
`nova volume-detach <server> <volume>`
* ボリューム削除
`cinder delete <volume>`
`openstack volume delete <volume>`

### OpenStack Identity - Keystone

* トークン発行
`openstack token issue`
* 認証情報確認
`source credrc.sh` ファイル例：

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

* 認証情報確認
`export | grep OS_`
* プロジェクト作成
`openstack project create --description "text" <project name>`
* ユーザー作成・削除
`openstack user create <name> --password pass`
`openstack user delete <name>`
* ロール一覧
`openstack role list`
* プロジェクト内ユーザーのロール変更
`openstack role add --user <user> --project <project> <role>`
* プロジェクトのクォータ表示
`openstack quota show <project id>`
`nova quota-show --tenant <project id>`
* プロジェクトのクォータ更新
`openstack quota set --<key> <value> <project id>`
`nova quota-update --<key> <value> <project id>`
* ポリシー変更

```sh
vim /etc/glance/policy.json
...
    "add_image": "role:admin",
...
```

* キーペア作成・一覧
`nova keypair-add <name> --pub-key <path/to/public/key>`
`openstack keypair create <name> --pub-key <path/to/public/key>`
`nova keypair-list`
* セキュリティグループにSSH許可ルール追加
`openstack security group rule create <rule name> --ingress --dst-port 22:22 --protocol tcp --remote-ip 0.0.0.0/0 <group name>`
`nova secgroup-add-rule <group name> <ip-proto> <from-port> <to-port>`
`例: nova secgroup-add-rule novasg2 tcp 22 22 0.0.0.0/24`
* セキュリティグループ・ルール一覧
`openstack security group list`
`openstack security group rule list`

### OpenStackオブジェクトストレージ - Swift

アカウントはユーザーアカウントではなく、swift内の名前空間/プロジェクトのようなものです。
コンテナはディレクトリのようなものです。

|タスク|コマンド|
|---|---|
|アカウント情報取得   |`swift stat`|
|コンテナ作成|`swift post <container>`|
|アカウント内の全コンテナ一覧|`swift list`|
|コンテナ情報取得 |`swift stat <container>`|
|ファイル/ディレクトリをコンテナにアップロード|`swift upload --object-name <object> <containe> <file/firectory path>`|
|コンテナ内のファイル一覧 |`swift list <containe>`|
|ファイルダウンロード | `swift download <container> <object>`|
|コンテナにメタデータ追加 |`swift post --meta <color>:<value> <container>`|
|オブジェクト削除|`swift delete <container> <object>`|
|指定セグメントでファイルアップロード| `swift upload <container> <object> --segment-size <size>`|
|コンテナ削除| `swift delete <container>`|

例：
`swift upload uploads files/puppies.jpg --object-name picture`

1. uploadsコンテナに、gadget.example.com以外の誰でも読み取り可能なACLを追加
`swift post -r .r:*,-gadget.example.com uploads`
1. uploadsコンテナに、phoneプロジェクトの誰でも書き込み可能なACLを追加
`swift post -w phone:* uploads`

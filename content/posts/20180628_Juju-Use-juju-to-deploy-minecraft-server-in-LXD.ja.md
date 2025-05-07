---
title: '[Juju] JujuでLXDにMinecraftサーバーをデプロイする'
date: 2018-06-28 17:01:36
tags:
- Ubuntu
- Juju
---

JujuはAWS、Azure、Google Cloud Platform、MAAS、LXDなど、非常に多くのクラウドプロバイダーに対応したデプロイツールです。
この記事では、JujuとLXDを使ってOpenStackのテスト環境を構築する方法に焦点を当てます。

## LXDのインストール

LXDのインストールはとても簡単で、以下のコマンドを実行するだけです。

```bash
sudo apt-install lxd
```

lxdパッケージが見つからない場合は、以下のコマンドでPPA（Personal Package Archive）を追加し、再度インストールコマンドを実行してください。

```bash
sudo apt-add-repository ppa:ubuntu-lxc/stable
sudo apt update
sudo apt dist-upgrade
```

## LXDの設定

以下のコマンドを実行して、LXDの設定をステップバイステップで行います。

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

## jujuのインストール

以下のコマンドでjujuをインストールします。

```bash
$ sudo apt install juju
...（省略：インストールログ）...
```

インストールが完了したら、LXDを使って新しいコントローラーをブートストラップできます。
これは、jujuが管理サービス用の新しいLXDコンテナを作成することを意味します。

以下のコマンドでjuju-controllerというコントローラーを作成します。

```bash
$ juju bootstrap localhost juju-controller
...（省略：ブートストラップログ）...
```

これで新しいLXDコンテナが稼働していることが確認できます。

```bash
$ lxc list
...（省略：コンテナリスト）...
```

`juju status`を実行すると、まだ何も稼働していないことが確認できます。

```bash
$ juju status
...（省略：ステータス出力）...
```

## Minecraftサーバーのデプロイ

これでMinecraftサーバーをデプロイする準備ができました！
以下のコマンドでデプロイを指示します。コマンドはすぐに返ってきますが、サービスの準備ができたわけではありません。`juju status`で進捗を確認してください。

```bash
$ juju status
...（省略：Minecraftサーバーのデプロイ進行状況）...
```

上記のように、jujuがサーバーの作成を進めていることが分かります。また、`lxc list`コマンドでMinecraftサーバー用の新しいコンテナが作成されていることも確認できます。

```bash
$ lxc list
...（省略：コンテナリスト）...
```

しばらくすると、デプロイが完了し、サービスがアクティブになります。

```bash
$ juju status
...（省略：サービスがアクティブになった出力）...
```

これでMinecraftクライアントを起動し、10.229.139.124のポート25565に接続すれば、新しいMinecraftサーバーで遊ぶことができます！

サーバーを削除したい場合は、以下のコマンドを実行してください。
Minecraftサーバーに関連するすべてのサービスやサーバーが削除されます。

```bash
juju destroy-service minecraft
```

jujuコントローラーやそれが作成したすべてのサービス／サーバーも削除できます。
すべてを一括で削除するには、以下のコマンドが最も簡単です。

```bash
$ juju destroy-controller juju-controller --destroy-all-models
...（省略：削除ログ）...
```

すべてのコンテナが削除されたことを確認できます。

```bash
$ lxc list
...（省略：空のリスト）...
```

## OpenStackのデプロイ

Jujuを使えば、OpenStackのようなより複雑な環境もデプロイできます。

```bash
$ juju deploy cs:bundle/openstack-base-55
...（省略：OpenStackバンドルのデプロイログ）...
```

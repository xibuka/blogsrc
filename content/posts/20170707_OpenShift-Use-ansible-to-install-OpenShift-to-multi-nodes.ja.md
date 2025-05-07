---
title: '[OpenShift]複数ノードへのOpenShiftクイックインストール'
date: 2017-07-07 15:32:15
tags:
- Linux
- OpenShift
---

この記事では、ansibleを利用したatomic-openshift-installerコマンドによる複数ノードへのOpenShiftのクイックインストール方法を紹介します。

## ホスト準備

OpenShiftノードとして以下の仮想マシンを使用します。

|タイプ    | CPU | メモリ  | HDD   | ホスト名                | OS     |
|------- | --- | ---- | ----- | ------------------- | ------ |
| マスター | 1   | 2 GB | 20 GB | master.example.com  | RHEL 7 |
| ノード   | 1   | 2 GB | 20 GB | node1.example.com   | RHEL 7 |
| ノード   | 1   | 2 GB | 20 GB | node2.example.com   | RHEL 7 |

## ホスト登録

注意: RHEL以外のOSを使用している場合は、「## 必要なパッケージのインストール」セクションに進み、必要なパッケージをインストールしてください。インストールできない場合は、リポジトリを追加するか、rpmファイルを取得してください。

各ホストをRHSM(Red Hat Subscription Manager)に登録し、必要なパッケージにアクセスできるようにします。

1. 各ホストでRHSMに登録:

   ```bash
   # subscription-manager register --username=<user_name> --password=<password>
   ```

2. 利用可能なOpenShiftサブスクリプションを一覧表示:

   ```bash
   # subscription-manager list --available --matches '*OpenShift*'
   ```

3. OpenShift Container PlatformサブスクリプションのプールIDを見つけてアタッチ:

   ```bash
   # subscription-manager attach --pool=<pool_id>
   ```

4. すべてのリポジトリを無効化し、OpenShift Container Platform 3.5に必要なリポジトリのみ有効化:

   ```bash
   # subscription-manager repos --disable="*"
   # yum-config-manager --disable \*
   # subscription-manager repos \
       --enable="rhel-7-server-rpms" \
       --enable="rhel-7-server-extras-rpms" \
       --enable="rhel-7-server-ose-3.5-rpms" \
       --enable="rhel-7-fast-datapath-rpms"
   ```

## 必要なパッケージのインストール

以下のパッケージをインストールします。

   ```bash
   # yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec sos psacct
   # yum update
   # yum -y install atomic-openshift-utils atomic-openshift-excluder atomic-openshift-docker-excluder
   # atomic-openshift-excluder unexclude
   ```

## dockerのインストールと設定

### dockerのインストール

   ```bash
   # yum -y install docker
   ```

### docker設定ファイルにパラメータを追加

`/etc/sysconfig/docker`ファイルを編集し、`OPTIONS`パラメータに`--insecure-registry 172.30.0.0/16`を追加します。

   ```bash
   OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0/16'
   ```

### Dockerストレージの設定

ここではdockerストレージ用に追加のブロックデバイスを使用します。`/etc/sysconfig/docker-storage-setup`で`DEVS`にディスクデバイスのパス、`VG`に作成するボリュームグループ名を指定します。

   ```bash
   # cat <<EOF > /etc/sysconfig/docker-storage-setup
   DEVS=/dev/vdc
   VG=docker-vg
   EOF
   ```

その後、`docker-storage-setup`を実行し、`docker-vg`が作成されたことを確認します。

   ```bash
   # docker-storage-setup
   ...（省略: コマンド出力は英語のまま）...
   ```

### dockerサービスの有効化と起動

   ```bash
   # systemctl enable docker
   # systemctl start docker
   # systemctl is-active docker
   ```

## ホスト間アクセスの確保

各ホストでパスワードなしのSSHキーを生成します。

   ```bash
   # ssh-keygen
   ```

`id_rsa.pub`を各ホストにコピー:

   ```bash
   # for host in master.example.com \
       node1.example.com \
       node2.example.com; \
       do ssh-copy-id -i ~/.ssh/id_rsa.pub $host; \
       done
   ```

## クイックインストール

### 対話型インストールの実行

下記コマンドで対話型インストールを開始し、画面の指示に従ってOpenShiftクラスターを新規インストールします。

   ```bash
   $ atomic-openshift-installer install
   ...（省略: インストール出力は英語のまま）...
   ```

### 非対話型インストールの実行

非対話型インストールでは、事前定義した設定ファイルでインストールを実行できます。デフォルトの設定ファイルパスは*~/.config/openshift/installer.cfg.yml*です。設定ファイルを用意し、`-u`オプションでインストールコマンドを実行します。

   ```bash
   atomic-openshift-installer -u install
   ```

*install.cfg.yml*ファイルの簡単な例:

   ```~/.config/openshift/installer.cfg.yml
   ...（省略: 設定例は英語のまま）...
   ```

`-c`オプションで別パスの設定ファイルも指定可能です。

   ```bash
   atomic-openshift-installer -u -c </path/to/file> install
   ```

### インストールの確認

インストール完了後、

1. masterとnodeがReady状態で起動しているか確認。masterホストでrootとして実行:

   ```bash
   # oc get nodes
   ...（省略: コマンド出力は英語のまま）...
   ```

2. Webコンソールはmasterホスト名＋デフォルトポート8443でアクセス可能。このテスト環境では[https://master.openshift.com:8443/console](https://master.openshift.com:8443/console)です。

3. インストール確認後、各masterとnodeでatomic-openshiftパッケージをyumのexcludeリストに戻します:

   ```bash
   # atomic-openshift-excluder exclude
   ```

## アンインストール

以下のコマンドで全ホストからOpenShift Container Platformをアンインストールできます。

   ```sh
   $ atomic-openshift-installer uninstall
   ...（省略: アンインストール出力は英語のまま）...
   ```

設定ファイルを使う場合は、アンインストール時にもファイルパスを指定します:

   ```bash
   atomic-openshift-installer -c </path/to/file> uninstall
   ```

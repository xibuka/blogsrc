---
title: '[OpenShift]OpenShiftのインストールと最初のプロジェクト Hello-OpenShift 作成'
date: 2017-06-26 13:40:40
tags:
- OpenShift
- Linux
---

## Linux OSのインストールとネットワーク設定の確認

OpenShiftをインストールするにはLinux OSマシンが必要です。最小要件は以下の通りです。

| CPU | メモリ | ハードディスク | ネットワーク |
| --- | ------ | --------- | ------- |
| x86_64 1コア | 2 GB | 20 GB | IPv4|

まずCentOS 7.3を最小構成でインストールします。インストール後、IPアドレスを確認し、利用可能なIPがあることを確認します。以下はeth0のIPアドレスが"192.168.122.45"である例です。

```bash
[root@openshift ~]# ip a
...（省略: コマンド出力は英語のまま）...
```

OpenShiftはサービス提供のためにホスト名が必要です。"hostnamectl set-hostname"でホスト名を設定し、"hostname"で確認します。以下はホスト名が"openshift.example.com"である例です。

```bash
[root@openshift ~]# hostnamectl set-hostname openshift.example.com
[root@openshift ~]# hostname
openshift.example.com
```

## dockerのインストール

OpenShiftはコンテナエンジンとしてdockerを使用します。以下のコマンドでdockerをインストールします。

```bash
[root@openshift ~]# yum install -y docker
```

インストール後、dockerサービスを起動し有効化します。

```bash
[root@openshift ~]# systemctl start docker
[root@openshift ~]# systemctl enable docker
```

下記コマンドでdockerがインターネットからデータを取得できるか確認します。以下は"hello-openshift"コンテナを作成する例です。この小さなアプリはGoで書かれており、8080と8888ポートでリッスンします。（初回実行時はイメージがローカルにないため、ダウンロードに時間がかかります）

```bash
[root@openshift ~]# docker run -it openshift/hello-openshift
...（省略: コマンド出力は英語のまま）...
```

テスト後は"Ctrl+c"でイメージを停止します。

## OpenShiftのインストール

OpenShiftのインストール方法はいくつかありますが、理解を深めるためにOpenShiftサーバのバイナリをダウンロードし、手動でデプロイします。
[Download OpenShift Origin](https://www.openshift.org/download.html)からダウンロードできます。現時点の最新版は[v1.5.1-7b451fc-linux-64bit.tar.gz](https://github.com/openshift/origin/releases/download/v1.5.1/openshift-origin-server-v1.5.1-7b451fc-linux-64bit.tar.gz)です。

ファイルをダウンロードし、/opt/に展開します。

```bash
[root@openshift ~]# wget https://github.com/openshift/origin/releases/download/v1.5.1/openshift-origin-server-v1.5.1-7b451fc-linux-64bit.tar.gz
...（省略: コマンド出力は英語のまま）...
[root@openshift ~]# cd /opt/
[root@openshift opt]# ls
[root@openshift opt]# tar xf ~/openshift-origin-server-v1.5.1-7b451fc-linux-64bit.tar.gz
...（省略）...
[root@openshift opt]# ln -s openshift-origin-server-v1.5.1-7b451fc-linux-64bit/ openshift
```

/opt/openshiftを$PATHに追加するため、/etc/profileの末尾に以下を追記します。

```conf
PATH=$PATH:/opt/openshift
```

sourceコマンドで設定を有効化します。

```bash
[root@openshift ~]# source /etc/profile
```

これでopenshiftコマンドが使えるか確認できます。バージョン確認コマンドを実行し、OpenShiftのバージョンが1.5.1、Kubernetesが1.5.2、etcdが3.1.0であることが分かります。

```bash
[root@openshift ~]# openshift version
...（省略: コマンド出力は英語のまま）...
```

## OpenShiftの起動

"openshift start"と入力するだけでOpenShiftが起動します。ターミナルに多くのログが出力され、出力が止まるとOpenShiftの起動が完了します。

```bash
[root@openshift ~]# openshift start
...（省略）...
```

## OpenShiftへのアクセス

### WebコントロールUIの起動とログイン

`https://<OpenShift Hostname>:8443`にアクセスしてWebコントロールに入ります。セキュリティ警告は無視し、ログイン画面が表示されます。ユーザー名とパスワードに"dev"を入力してログインします。

![openshift login](/img/openshift-install/login.png)

### 新規プロジェクトの作成

「New Project」をクリックします。
![create pods](/img/openshift-install/createpods1.png)

最初のテストプロジェクトでは、Name、Display Name、Descriptionを入力し「Create」をクリックします。
![create pods](/img/openshift-install/createpods2.png)

次の画面で「Deploy Image」をクリックし、「Image Name」を選択します。イメージ名に"openshift/hello-openshift"を入力し、右側の「find」アイコンをクリックしてイメージを検索します。
![create pods](/img/openshift-install/createpods3.png)

しばらくすると（ネットワーク速度による）、イメージがダウンロードされ、ページ下部の「Create」をクリックしてpodを作成します。
![create pods](/img/openshift-install/createpods4.png)

OpenShiftはpodのデプロイを開始します。最初はグレーの円に数字"1"が表示されます。デプロイが完了すると円が青色になり、podが利用可能になったことを示します。
![create pods](/img/openshift-install/createpods5.png)
![create pods](/img/openshift-install/createpods6.png)

円をクリックするとpodの詳細情報が表示されます。podに割り当てられたIPが確認できます。以下の例ではpodのIPアドレスは"172.17.0.3"です。
![create pods](/img/openshift-install/createpods7.png)

OpenShiftサーバに戻り、以下のコマンドでhello-openshiftコンテナを確認します。hello-openshiftサービスは8080または8888ポートからのリクエストに"Hello OpenShift!"という文字列を返します。

```bash
[root@openshift ~]# curl 172.17.0.3:8080
Hello OpenShift!
```

以上がOpenShiftのインストールとプロジェクト/pod作成の簡単なテストです。このIPはOpenShiftサーバ外からはアクセスできません（ローカルIPのため）。実際に外部公開するには追加設定が必要です。今後追記予定。 #TODO

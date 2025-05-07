---
title: OpenShift HTPasswdによる認証とユーザーエージェントの設定
date: 2017-07-12 14:43:47
tags:
- OpenShift
- Linux
---

Ansible方式でOpenShiftをインストールすると、デフォルトでidentity providerは*Deny all*に設定され、すべてのユーザーのアクセスが拒否されます。ユーザーのアクセスを許可するには、別のidentity providerを選択し、*master設定ファイル*を編集する必要があります。デフォルトの*master設定ファイル*は*/etc/origin/master/master-config.yaml*にあります。
OpenShiftには複数のidentity providerがあり、ユーザー認証の管理が可能です。今回は**HTPasswd**を使います。
詳細は[Configuring Authentication and User Agent](https://docs.openshift.com/container-platform/3.5/install_config/configuring_authentication.html)を参照してください。

## パッケージのインストール

htpasswdユーティリティはhttpd-toolsパッケージに含まれています。

```bash
yum install httpd-tools
```

## master設定ファイルの編集

```yaml
oauthConfig:
  ...
  identityProviders:
  - name: my_htpasswd_provider 
    challenge: true 
    login: true 
    mappingMethod: claim 
    provider:
      apiVersion: v1
      kind: HTPasswdPasswordIdentityProvider
      file: /path/to/users.htpasswd 
```

`atomic-openshift-master`を再起動して設定を反映させます。

```sh
systemctl restart atomic-openshift-master
```

## ユーザー名とパスワードの設定

HTPasswdはフラットファイルでユーザー名とパスワード（ハッシュ化）を管理します。以下のコマンドでファイルを作成し、*username*のパスワードを入力します。

```sh
$ htpasswd -c </path/to/users.htpasswd> user1
New password:
Re-type new password:
Adding password for user user1
```

`-b`オプションを付けるとパスワードをコマンドラインで指定できます。

```sh
htpasswd -c -b user1 <password>
```

ユーザーを追加したら、そのユーザーでOpenShift Container Platformにアクセスできます。

## ユーザーの追加・更新

ユーザー名を追加・更新するには以下のコマンドを実行します。

```sh
htpasswd </path/to/users.htpasswd> <user_name>
```

## ユーザーの削除

ユーザー名を削除するには以下のコマンドを実行します。

```sh
htpasswd -D </path/to/users.htpasswd> <user_name>
```

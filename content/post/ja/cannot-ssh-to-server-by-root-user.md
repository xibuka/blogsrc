---
title: cannot ssh to server as root
date: 2017-02-16 16:36:12
tags: 
- Linux
- sshd
---
rootパスワードを知っているのに、rootでssh接続できない問題の解決方法です。

実はsshdの設定ファイルに、rootでのログイン許可を設定するパラメータがあります。
Linux環境では、設定ファイル/etc/ssh/sshd_configに対し

```/etc/ssh/sshd_config
PermitRootLogin no
```

を

```/etc/ssh/sshd_config
PermitRootLogin yes
```
に変更し、sshdを再起動すれば、アクセス出来るようになる。

<!-- more -->

```
# systemctl restart sshd
```

また、以下のように自動ログインをOFFにするパラメータも存在する

```
PubkeyAuthentication no
```

特定のIPに対しての個別設定も可能

```
Match Address 172.25.0.11
    PubkeyAuthentication no
```

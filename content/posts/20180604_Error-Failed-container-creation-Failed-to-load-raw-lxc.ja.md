---
title: 'エラー: コンテナ作成失敗: raw.lxcの読み込みに失敗'
date: 2018-06-04 16:19:39
tags:
- Ubuntu
- MaaS
---

以下のURLを参考にMaaSのインストールとテストを試みました。

[https://docs.maas.io/2.1/en/installconfig-lxd-install](https://docs.maas.io/2.1/en/installconfig-lxd-install)

上記ドキュメントのプロファイル編集部分より

1. `lxc profile edit maas`
1. configの後ろの{}を以下の内容（config:は除く）に置き換えます：

    ```yaml
    config:
      raw.lxc: |-
        lxc.cgroup.devices.allow = c 10:237 rwm
        lxc.aa_profile = unconfined
        lxc.cgroup.devices.allow = b 7:* rwm
      security.privileged: "true"
    ```

1. launch手順で以下のエラーが発生しました：

    ```sh
    $ lxc launch -p maas ubuntu:16.04 xenial-maas
    Creating xenial-maas
    Error: Failed container creation: Failed to load raw.lxc
    ```

これは自分がLXD 3.0を使っているためで、上記の設定キーが古いことが原因です。
[このコメント](https://github.com/lxc/lxd/issues/4393#issuecomment-378181793)によると、lxd 2.1以降は`lxc.aa_profile`が`lxc.apparmor.profile`に変更されています。

したがって、回避策は以下の通りです。

1. 再度 `lxc profile edit maas`
1. `lxc.aa_profile` を `lxc.apparmor.profile` に置き換えます。

    ```yaml
    config:
      raw.lxc: |-
        lxc.cgroup.devices.allow = c 10:237 rwm
        lxc.apparmor.profile = unconfined
        lxc.cgroup.devices.allow = b 7:* rwm
      security.privileged: "true"
    ```

1. launchコマンドを再実行します。

    ```sh
    $ lxc launch -p maas ubuntu:16.04 xenial-maas
    Creating xenial-maas
    Starting xenial-maas
    ```

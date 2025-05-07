---
title: "Multipassの起動がネットワークタイムアウトで失敗する"
date: 2020-03-31T10:04:31+09:00
draft: false
tags:
- Ubuntu
---

MultipassはUbuntuのVMインスタンスを作成するのに非常に便利なツールです。
CLIでLinuxインスタンスの起動や管理ができ、クラウドイメージのダウンロードも自動で行われ、数分でVMを立ち上げることができます。

[https://multipass.run/](https://multipass.run/)

しかし、私の場合、multipass 1.1.0でインスタンスをクイック起動しようとしたところ、`Network timeout` エラーで失敗しました。

```bash
$ multipass version
 multipass  1.1.0
 multipassd 1.1.0

$ multipass launch
launch failed: failed to download from 'http://cloud-images.ubuntu.com/releases/server/releases/bionic/release-20200317/ubuntu-18.04-server-cloudimg-amd64.img': Network timeout
```

このリンクを `wget` で確認したところ問題なかったので、イメージのダウンロード時間がmultipassのタイムアウト値を超えているのではと推測しました。
手動でダウンロードして、そのイメージを使ってインスタンスを起動できるか？もちろん可能です。
イメージをダウンロードし、そのパスをパラメータとして渡せばOKです。

```bash
$ multipass launch file:///home/wshi/Downloads/ubuntu-18.04-server-cloudimg-amd64.img
Launched: lucrative-eelpout 
```

日本でのダウンロード時間についてもう1点。
`http://cloud-images.ubuntu.com` は私の環境では遅かったので、富山大学のミラー `http://ubuntutym2.u-toyama.ac.jp/cloud-images/releases/` を利用しました。
オリジナルより10倍速く、参考になれば幸いです。

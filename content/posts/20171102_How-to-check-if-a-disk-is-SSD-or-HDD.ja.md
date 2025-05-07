---
title: ディスクがSSDかHDDかを確認する方法
date: 2017-11-02 08:27:14
tags:
- Linux
---

LinuxはSSDを自動的に検出します。
カーネルバージョン2.6.29以降、以下のコマンドで`/dev/sda`を確認できます。

```bash
# cat /sys/block/sda/queue/rotational
```

返り値が`0`なら`/dev/sda`はSSD、`1`ならHDDです。
なお、ハードウェアRAIDで作成されたディスクの場合、このコマンドは動作しないことがあります。

もう一つの方法は、util-linuxパッケージの一部である`lsblk`コマンドを使うことです。

```bash
# lsblk -d -o name,rota
NAME ROTA
sda     0
sdb     1
```

`ROTA`は回転デバイスを意味し、`1`がHDD、`0`がSSDを示します。
このコマンドは`/sys/block/.../queue/rotational`と同じ情報を表示します。

参考: [How to know if a disk is an SSD or an HDD](https://unix.stackexchange.com/questions/65595/how-to-know-if-a-disk-is-an-ssd-or-an-hdd)

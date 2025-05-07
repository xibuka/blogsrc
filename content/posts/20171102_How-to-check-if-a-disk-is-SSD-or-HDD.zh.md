---
title: 如何判断磁盘是SSD还是HDD
date: 2017-11-02 08:27:14
tags:
- Linux
---

Linux会自动检测SSD。
自内核2.6.29版本起，可以用如下命令检查`/dev/sda`：

```bash
# cat /sys/block/sda/queue/rotational
```

返回值为`0`表示`/dev/sda`是SSD，`1`表示是HDD。
注意，如果你的磁盘是由硬件RAID创建的，这个命令可能无效。

另一种方法是使用util-linux包中的`lsblk`命令：

```bash
# lsblk -d -o name,rota
NAME ROTA
sda     0
sdb     1
```

`ROTA`表示是否为旋转设备，`1`为HDD，`0`为SSD。
这个命令显示的信息和`/sys/block/.../queue/rotational`一致。

参考：[How to know if a disk is an SSD or an HDD](https://unix.stackexchange.com/questions/65595/how-to-know-if-a-disk-is-an-ssd-or-an-hdd)

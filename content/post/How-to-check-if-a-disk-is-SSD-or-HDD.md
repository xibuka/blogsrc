---
title: How to check if a disk is SSD or HDD
date: 2017-11-02 08:27:14
tags:
- Linux
---

Linux will detects SSD automatically.
Since kernel version 2.6.29, you can check `/dev/sda` with following command

```
# cat /sys/block/sda/queue/rotational
```

The return number `0` shows you `/dev/sda` is a SSD, and `1` shows it is a HDD.
Note that this command may not work when your disk is created by hardware RAID.

Another way is to use `lsblk` command, a part of the util-linux package.

```
# lsblk -d -o name,rota
NAME ROTA
sda     0
sdb     1
```

`ROTA` means rotational device, `1` for true, `0` for false.
This command report the same information as in `/sys/block/.../queue/rotational`

Ref : [How to know if a disk is an SSD or an HDD](https://unix.stackexchange.com/questions/65595/how-to-know-if-a-disk-is-an-ssd-or-an-hdd)



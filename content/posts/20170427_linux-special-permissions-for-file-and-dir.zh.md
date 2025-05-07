---
title: 文件和目录的特殊权限
date: 2017-04-27 23:59:20
tags:
- Linux
---

## 特殊权限说明

文件和文件夹有三种特殊权限：setuid、setgid 和 sticky bit。
setuid 和 setgid 权限表示命令以文件所有者或组的身份执行，而不是以运行命令的用户或组的身份执行。
sticky bit 权限对文件删除有特殊限制：只有文件所有者和 root 可以删除目录中的文件。

特殊权限 | 对文件的影响 | 对目录的影响
----------|----------------|----------------
u+s (suid) | 文件以所有者身份执行，而不是以运行者身份执行。 | 无影响
g+s (sgid) | 文件以所属组身份执行。 | 目录中新建文件的所属组与目录的组相同。
o+t (sticky) | 无影响 | 具有写权限的用户只能删除自己拥有的文件，不能删除或修改他人拥有的文件。

## 设置特殊权限

符号方式：setuid = u+s；setgid = g+s；sticky = o+t
数字方式：setuid = 4；   setgid = 2；   sticky = 1

示例

```bash
chmod g+s file  # 给文件添加 setgid 位
chmod 1755 file # 给文件添加 sticky 位
```

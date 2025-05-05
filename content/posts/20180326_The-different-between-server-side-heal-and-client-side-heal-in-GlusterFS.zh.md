---
title: GlusterFS 中服务端修复与客户端修复的区别
date: 2018-03-26 09:56:21
tags:
- GlusterFS
---

在 GlusterFS 中有两种修复（heal）机制：服务端修复和客户端修复。

服务端修复由所有 gluster 服务器节点上的 self-heal 守护进程自动执行。它会从 brick 路径下的 .glusterfs 目录中遍历文件和目录信息进行修复，因此可以从服务器端保持文件数据和元数据的一致性。

客户端修复则不同，当客户端从挂载路径访问文件时（即文件描述符上的操作），会针对该特定文件触发修复。这意味着每次文件访问操作都会多经过一组函数调用来检查和修复文件，可能会带来一定的性能影响。客户端修复默认是开启的，可以通过以下命令关闭：

文件数据

```sh
gluster volume set <volume name> cluster.data-self-heal off
```

目录项数据（目录内容/条目）

```sh
gluster volume set <volume name> cluster.entry-self-heal off
```

元数据

```sh
gluster volume set <volume name> cluster.metadata-self-heal off
```

需要注意的是，关闭客户端修复并不意味着会影响数据的完整性和一致性。对于文件读取，会评估副本的 pending xattr，只会从正确的副本读取。对于文件写入，新数据会写入所有副本 brick，gluster 节点上的 self-heal 守护进程会在需要时自动修复。

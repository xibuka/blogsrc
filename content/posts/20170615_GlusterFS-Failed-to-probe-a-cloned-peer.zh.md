---
title: GlusterFS 克隆节点探测失败
date: 2017-06-15 11:43:46
tags:
- GlusterFS
---
如果你想节省每次搭建 gluster 系统的时间，可以在一台虚拟机上配置好所有内容，然后克隆它。
但这样做后，在其他节点上探测 peer 时可能会遇到问题。
当你尝试运行如下命令时，可能会遇到如下报错：

```bash
[root@node1 ~]# gluster peer probe node2
peer probe: failed: Peer uuid (host node2) is same as local uuid
```

这是因为 glusterfs-server 包首次安装时，会在 /var/lib/glusterd/glusterd.info 生成一个节点 UUID 文件。
所以如果你克隆了已安装 glusterfs 的虚拟机，所有虚拟机上都会有相同的 glusterd.info 和 UUID。

解决方法如下：

1. 在所有节点上停止 glusterd 服务
2. 删除 /var/lib/glusterd/glusterd.info
3. 在所有节点上启动 glusterd 服务
4. 再次运行 peer probe 命令

第3步后，系统会生成带有新 UUID 的 glusterd.info 文件，问题即可彻底解决。

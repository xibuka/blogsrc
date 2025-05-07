---
title: "Multipass 启动因网络超时失败"
date: 2020-03-31T10:04:31+09:00
draft: false
tags:
- Ubuntu
---

Multipass 是一个非常实用的工具，可以用来创建 Ubuntu 虚拟机实例。
它提供了一个 CLI 来启动和管理 Linux 实例。云镜像的下载也是自动完成的，几分钟内就能启动一个 VM。

[https://multipass.run/](https://multipass.run/)

但在我的情况下，我尝试用 multipass 1.1.0 快速启动实例时，遇到了 `Network timeout` 错误。

```bash
$ multipass version
 multipass  1.1.0
 multipassd 1.1.0

$ multipass launch
launch failed: failed to download from 'http://cloud-images.ubuntu.com/releases/server/releases/bionic/release-20200317/ubuntu-18.04-server-cloudimg-amd64.img': Network timeout
```

我用 `wget` 检查了这个链接，没有问题，所以我猜测镜像下载时间太长，超过了 multipass 的某个超时设置。
能否手动下载镜像并用它来启动实例？当然可以。
你可以先下载镜像，然后将镜像路径作为参数传递。

```bash
$ multipass launch file:///home/wshi/Downloads/ubuntu-18.04-server-cloudimg-amd64.img
Launched: lucrative-eelpout 
```

关于在日本的下载速度还有一点补充。
`http://cloud-images.ubuntu.com` 在我这里速度很慢，所以我换用了富山大学的镜像 `http://ubuntutym2.u-toyama.ac.jp/cloud-images/releases/`。
比官方源快了10倍，希望对你有帮助。

---
title: '[Juju] 使用 juju 在 LXD 中部署 Minecraft 服务器'
date: 2018-06-28 17:01:36
tags:
- Ubuntu
- Juju
---

Juju 是一个支持多种云服务商（如 AWS、Azure、Google Cloud Platform、MAAS 和 LXD）的部署工具。本文将重点介绍如何使用 Juju 和 LXD 构建 OpenStack 测试环境。

## 安装 LXD

安装 LXD 非常简单，只需运行以下命令：

```bash
sudo apt-install lxd
```

如果找不到 lxd 包，请运行以下命令添加 PPA（Personal Package Archive），然后重新执行安装命令。

```bash
sudo apt-add-repository ppa:ubuntu-lxc/stable
sudo apt update
sudo apt dist-upgrade
```

## 配置 LXD

运行以下命令，按步骤配置 lxd 设置：

```bash
$ sudo lxd init
Do you want to configure a new storage pool (yes/no) [default=yes]?
Name of the storage backend to use (dir or zfs) [default=dir]:
Would you like LXD to be available over the network (yes/no) [default=no]?
Do you want to configure the LXD bridge (yes/no) [default=yes]?
Warning: Stopping lxd.service, but it can still be activated by:
  lxd.socket
LXD has been successfully configured.
```

## 安装 juju

运行以下命令安装 juju：

```bash
$ sudo apt install juju
...（省略：安装日志）...
```

安装完成后，我们可以使用 LXD 启动一个新的控制器。这意味着 juju 会为管理服务创建一个新的 LXD 容器。

可以用以下命令创建名为 juju-controller 的控制器：

```bash
$ juju bootstrap localhost juju-controller
...（省略：引导日志）...
```

此时可以看到有一个新的 LXD 容器正在运行。

```bash
$ lxc list
...（省略：容器列表）...
```

运行 `juju status` 可以看到当前还没有任何服务在运行。

```bash
$ juju status
...（省略：状态输出）...
```

## 部署 Minecraft 服务器

现在我们可以部署 Minecraft 服务器了！
运行以下命令告诉 juju 你要部署它。命令会立即返回，但这并不意味着服务已经准备好。请用 `juju status` 查看进度。

```bash
$ juju status
...（省略：Minecraft 服务器部署进度）...
```

从上面可以看到 juju 正在创建服务器。用 `lxc list` 命令也可以看到为 Minecraft 服务器创建的新容器。

```bash
$ lxc list
...（省略：容器列表）...
```

过一会儿，部署完成，服务变为 active。

```bash
$ juju status
...（省略：服务变为 active 的输出）...
```

现在你可以启动 Minecraft 客户端，连接 10.229.139.124 的 25565 端口，畅玩你的全新 Minecraft 服务器！

如果想删除它，只需运行以下命令。
与 Minecraft 服务器相关的所有服务和服务器都会被移除。

```bash
juju destroy-service minecraft
```

你也可以销毁 juju 控制器以及它创建的所有服务/服务器。
最简单的一键销毁方法如下：

```bash
$ juju destroy-controller juju-controller --destroy-all-models
...（省略：销毁日志）...
```

可以确认所有容器都已被移除。

```bash
$ lxc list
...（省略：空列表）...
```

## 部署 OpenStack

你可以用 Juju 部署更复杂的环境，比如 OpenStack。

```bash
$ juju deploy cs:bundle/openstack-base-55
...（省略：OpenStack bundle 部署日志）...
```

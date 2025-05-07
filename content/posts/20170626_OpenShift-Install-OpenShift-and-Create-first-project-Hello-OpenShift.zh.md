---
title: '[OpenShift]安装 OpenShift 并创建第一个项目 Hello-OpenShift'
date: 2017-06-26 13:40:40
tags:
- OpenShift
- Linux
---

## 安装 Linux 系统并确认网络设置

你需要创建一台 Linux 系统的机器来安装 OpenShift。最低要求如下：

| CPU | 内存 | 硬盘 | 网络 |
| --- | ------ | --------- | ------- |
| x86_64 1核 | 2 GB | 20 GB | IPv4|

首先安装 CentOS 7.3，选择最小化安装。安装完成后，检查你的 IP 地址，确保有可用的 IP。如下例 eth0 的 IP 地址为 "192.168.122.45"。

```bash
[root@openshift ~]# ip a
...（省略：命令输出为英文原文）...
```

OpenShift 需要主机名来提供服务。用 "hostnamectl set-hostname" 设置主机名，并用 "hostname" 确认。如下例主机名为 "openshift.example.com"。

```bash
[root@openshift ~]# hostnamectl set-hostname openshift.example.com
[root@openshift ~]# hostname
openshift.example.com
```

## 安装 docker

Openshift 使用 docker 作为容器引擎。用如下命令安装 docker。

```bash
[root@openshift ~]# yum install -y docker
```

安装完成后，启动并设置 docker 服务开机自启。

```bash
[root@openshift ~]# systemctl start docker
[root@openshift ~]# systemctl enable docker
```

用如下命令测试 docker 是否能从互联网拉取镜像。以下示例创建了一个 "hello-openshift" 容器。这个小程序是用 go 写的，会监听 8080 和 8888 端口。（首次运行会拉取镜像，需等待下载完成）

```bash
[root@openshift ~]# docker run -it openshift/hello-openshift
...（省略：命令输出为英文原文）...
```

测试完成后，按 "Ctrl+c" 停止该镜像。

## 安装 OpenShift

OpenShift 有多种安装方式。为了便于理解，这里手动下载 OpenShift server 的二进制包并部署。
下载地址见 [Download OpenShift Origin](https://www.openshift.org/download.html)。当前最新版为 [v1.5.1-7b451fc-linux-64bit.tar.gz](https://github.com/openshift/origin/releases/download/v1.5.1/openshift-origin-server-v1.5.1-7b451fc-linux-64bit.tar.gz)。

下载文件并解压到 /opt/ 目录。

```bash
[root@openshift ~]# wget https://github.com/openshift/origin/releases/download/v1.5.1/openshift-origin-server-v1.5.1-7b451fc-linux-64bit.tar.gz
...（省略：命令输出为英文原文）...
[root@openshift ~]# cd /opt/
[root@openshift opt]# ls
[root@openshift opt]# tar xf ~/openshift-origin-server-v1.5.1-7b451fc-linux-64bit.tar.gz
...（省略）...
[root@openshift opt]# ln -s openshift-origin-server-v1.5.1-7b451fc-linux-64bit/ openshift
```

将 Openshift 路径加入 $PATH，在 /etc/profile 末尾添加如下内容：

```conf
PATH=$PATH:/opt/openshift
```

用 source 命令使配置生效：

```bash
[root@openshift ~]# source /etc/profile
```

此时可用 openshift 命令，试试查看版本。输出中可见 Openshift 版本为 1.5.1，Kubernetes 为 1.5.2，etcd 为 3.1.0。

```bash
[root@openshift ~]# openshift version
...（省略：命令输出为英文原文）...
```

## 启动 OpenShift

只需输入 "openshift start" 即可启动 OpenShift。终端会输出大量日志，日志停止后即启动完成。

```bash
[root@openshift ~]# openshift start
...（省略）...
```

## 访问 OpenShift

### 打开 Web 控制台并登录

在浏览器输入 `https://<OpenShift Hostname>:8443` 访问 Web 控制台。忽略安全警告，进入登录页面。用户名和密码均输入 "dev" 登录。

![openshift login](/img/openshift-install/login.png)

### 创建新项目

点击 "New Project"
![create pods](/img/openshift-install/createpods1.png)

首次测试项目，输入 Name、Display Name 和 Description，点击 "Create"。
![create pods](/img/openshift-install/createpods2.png)

在下一个页面点击 "Deploy Image"，选择 "Image Name"，输入镜像名 "openshift/hello-openshift"，点击右侧的 "find" 图标查找镜像。
![create pods](/img/openshift-install/createpods3.png)

等待镜像下载完成后，点击页面底部的 "Create" 创建 pod。
![create pods](/img/openshift-install/createpods4.png)

OpenShift 会开始部署 pod，最初会看到一个灰色圆圈，里面有数字 "1"。部署完成后圆圈变为蓝色，表示 pod 已就绪。
![create pods](/img/openshift-install/createpods5.png)
![create pods](/img/openshift-install/createpods6.png)

点击圆圈可查看 pod 详细信息。可以看到分配给 pod 的 IP。如下例 pod 的 IP 地址为 "172.17.0.3"。
![create pods](/img/openshift-install/createpods7.png)

回到 OpenShift 服务器，运行如下命令检查 hello-openshift 容器。hello-openshift 服务会对 8080 或 8888 端口的请求返回 "Hello OpenShift!"。

```bash
[root@openshift ~]# curl 172.17.0.3:8080
Hello OpenShift!
```

以上就是 OpenShift 安装和创建项目/pod 的简单测试。该 IP 仅本机可访问（为本地 IP）。如需对外提供服务，还需进一步设置。后续补充。#TODO

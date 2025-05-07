---
title: '[OpenShift]快速在多节点安装 OpenShift'
date: 2017-07-07 15:32:15
tags:
- Linux
- OpenShift
---

本文介绍如何使用 ansible 驱动的 atomic-openshift-installer 快速命令，在多节点上安装 OpenShift。

## 主机准备

我使用如下虚拟机作为 OpenShift 节点：

|类型    | CPU | 内存  | 硬盘   | 主机名                | 操作系统     |
|------- | --- | ---- | ----- | ------------------- | ------ |
| Master | 1   | 2 GB | 20 GB | master.example.com  | RHEL 7 |
| node   | 1   | 2 GB | 20 GB | node1.example.com   | RHEL 7 |
| node   | 1   | 2 GB | 20 GB | node2.example.com   | RHEL 7 |

## 主机注册

注意：如果你使用的不是 RHEL，请直接跳到"## 安装必要软件包"部分安装相关包。如果有包无法安装，可以尝试添加仓库或手动下载 rpm 文件。

每台主机都需要通过 RHSM（Red Hat Subscription Manager）注册，以获取所需软件包。

1. 在每台主机上注册 RHSM：

   ```bash
   # subscription-manager register --username=<user_name> --password=<password>
   ```

2. 列出可用的 OpenShift 订阅：

   ```bash
   # subscription-manager list --available --matches '*OpenShift*'
   ```

3. 找到 OpenShift Container Platform 订阅的 pool ID 并绑定：

   ```bash
   # subscription-manager attach --pool=<pool_id>
   ```

4. 禁用所有仓库，仅启用 OpenShift Container Platform 3.5 所需仓库：

   ```bash
   # subscription-manager repos --disable="*"
   # yum-config-manager --disable \*
   # subscription-manager repos \
       --enable="rhel-7-server-rpms" \
       --enable="rhel-7-server-extras-rpms" \
       --enable="rhel-7-server-ose-3.5-rpms" \
       --enable="rhel-7-fast-datapath-rpms"
   ```

## 安装必要软件包

安装如下软件包：

   ```bash
   # yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec sos psacct
   # yum update
   # yum -y install atomic-openshift-utils atomic-openshift-excluder atomic-openshift-docker-excluder
   # atomic-openshift-excluder unexclude
   ```

## 安装并配置 docker

### 安装 docker

   ```bash
   # yum -y install docker
   ```

### 修改 docker 配置文件参数

编辑 `/etc/sysconfig/docker` 文件，在 `OPTIONS` 参数中添加 `--insecure-registry 172.30.0.0/16`。

   ```bash
   OPTIONS='--selinux-enabled --insecure-registry 172.30.0.0/16'
   ```

### 配置 Docker 存储

这里为 docker 存储使用额外的块设备。在 `/etc/sysconfig/docker-storage-setup` 中，设置 `DEVS` 为磁盘设备路径，`VG` 为要创建的卷组名。

   ```bash
   # cat <<EOF > /etc/sysconfig/docker-storage-setup
   DEVS=/dev/vdc
   VG=docker-vg
   EOF
   ```

然后运行 `docker-storage-setup`，确认 `docker-vg` 已创建。

   ```bash
   # docker-storage-setup
   ...（省略：命令输出为英文原文）...
   ```

### 启用并启动 docker 服务

   ```bash
   # systemctl enable docker
   # systemctl start docker
   # systemctl is-active docker
   ```

## 确保主机互通

在每台主机上生成无密码 SSH 密钥：

   ```bash
   # ssh-keygen
   ```

将 `id_rsa.pub` 拷贝到每台主机：

   ```bash
   # for host in master.example.com \
       node1.example.com \
       node2.example.com; \
       do ssh-copy-id -i ~/.ssh/id_rsa.pub $host; \
       done
   ```

## 快速安装

### 交互式安装

运行如下命令启动交互式安装，按提示完成 OpenShift 集群安装：

   ```bash
   $ atomic-openshift-installer install
   ...（省略：安装输出为英文原文）...
   ```

### 非交互式安装

非交互式安装允许你用预定义的配置文件进行安装。默认配置文件路径为 *~/.config/openshift/installer.cfg.yml*。准备好配置文件后，使用 `-u` 选项运行安装命令。

   ```bash
   atomic-openshift-installer -u install
   ```

*install.cfg.yml* 文件示例：

   ```~/.config/openshift/installer.cfg.yml
   ...（省略：配置示例为英文原文）...
   ```

你也可以用 `-c` 选项指定其他配置文件路径。

   ```bash
   atomic-openshift-installer -u -c </path/to/file> install
   ```

### 验证安装

安装完成后：

1. 验证 master 和 node 是否为 Ready 状态。在 master 主机上以 root 运行：

   ```bash
   # oc get nodes
   ...（省略：命令输出为英文原文）...
   ```

2. Web 控制台使用 master 主机名和默认端口 8443。在本测试环境下为 [https://master.openshift.com:8443/console](https://master.openshift.com:8443/console)

3. 验证安装后，在每台 master 和 node 上运行如下命令，将 atomic-openshift 包重新加入 yum exclude 列表：

   ```bash
   # atomic-openshift-excluder exclude
   ```

## 卸载

可用如下命令从所有主机卸载 OpenShift Container Platform：

   ```sh
   $ atomic-openshift-installer uninstall
   ...（省略：卸载输出为英文原文）...
   ```

如果使用了配置文件，卸载时也可指定文件路径：

   ```bash
   atomic-openshift-installer -c </path/to/file> uninstall
   ```

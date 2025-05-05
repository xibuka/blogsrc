---
title: "Rancher 从零学习"
date: 2020-06-09T16:12:08+09:00
draft: false
---

## 介绍

Rancher 由 `rancher-server`、`rancher-agent` 以及一个或多个 `kubernetes cluster` 组成。其中，`rancher-agent` 运行在被管理的 `kubernetes` 上，与 `rancher-server` 通信并发送集群信息。

`rancher-server` 提供用于管理 `kubernetes` 的 WebUI 和 API。`rancher-server` 只能通过 HTTPS 访问。

## 安装

### 单节点

单节点有两种搭建方式：

- 直接用 `docker` 运行 `rancher-server`
- 用 `rke` 在单节点上启用所有 `role`

`rke` 的方法后面会介绍，这里先用 `docker` 的方法。

在要运行 `rancher-server` 的节点上输入如下命令：

```bash
docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  rancher/rancher:latest
```

这样就启动了单节点的 `rancher-server`，可通过 `http://<IP Address>` 访问。

### 多节点

用 `rke` 构建 HA 环境的 `rancher-server`。

`rke (rancher k8s engine)` 是用于搭建 `kubernetes` 集群的命令行工具，环境准备好后只需一条命令即可搭建集群。

#### 准备机器

这里用 `multipass` 准备机器。以下命令会创建 6 台虚拟机：

```bash
multipass launch -c 2 -m 4096M -d 20G --cloud-init=./cloud-init.yaml -n kmaster1
multipass launch -c 2 -m 4096M -d 20G --cloud-init=./cloud-init.yaml -n kmaster2
multipass launch -c 2 -m 4096M -d 20G --cloud-init=./cloud-init.yaml -n kmaster3
multipass launch -c 2 -m 4096M -d 20G --cloud-init=./cloud-init.yaml -n kworker1
multipass launch -c 2 -m 4096M -d 20G --cloud-init=./cloud-init.yaml -n kworker2
multipass launch -c 2 -m 4096M -d 20G --cloud-init=./cloud-init.yaml -n kworker3
```

命令中的 `cloud-init.yaml` 文件会在机器启动后执行后置处理。本例中执行了如下操作：

- 安装 `docker`
- 注册主机的 `ssh` 密钥
- 将 `Ubuntu` 用户加入 `docker` 组
- 加载所需内核模块
- 关闭 swap

详细内容如下：

```cloud-init
#cloud-config

packages:
    - docker.io

ssh_authorized_keys:
    - <rsa public key>

runcmd:
    - usermod -aG docker ubuntu
    - modprobe br_netfilter
    - modprobe ip6_udp_tunnel
    - modprobe ip_set
    - modprobe ip_set_hash_ip
    - modprobe ip_set_hash_net
    - modprobe iptable_filter
    - modprobe iptable_nat
    - modprobe iptable_mangle
    - modprobe iptable_raw
    - modprobe nf_conntrack_netlink
    - modprobe nf_conntrack
    - modprobe nf_conntrack_ipv4
    - modprobe nf_defrag_ipv4
    - modprobe nf_nat
    - modprobe nf_nat_ipv4
    - modprobe nf_nat_masquerade_ipv4
    - modprobe nfnetlink
    - modprobe udp_tunnel
    - modprobe veth
    - modprobe vxlan
    - modprobe x_tables
    - modprobe xt_addrtype
    - modprobe xt_conntrack
    - modprobe xt_comment
    - modprobe xt_mark
    - modprobe xt_multiport
    - modprobe xt_nat
    - modprobe xt_recent
    - modprobe xt_set
    - modprobe xt_statistic
    - modprobe xt_tcpudp
    - swapoff -a
```

最终会有如下 6 台机器：

```bash
$ multipass list
Name                    State             IPv4             Image
kmaster1                Running           10.131.158.97    Not Available
kmaster2                Running           10.131.158.194   Not Available
kmaster3                Running           10.131.158.121   Not Available
kworker1                Running           10.131.158.133   Not Available
kworker2                Running           10.131.158.247   Not Available
kworker3                Running           10.131.158.166   Not Available
```

#### 用 rke 创建 Kubernetes 环境

如 [rke](https://rancher.com/products/rke/) 所述，下载二进制文件并添加执行权限。

设置上述 6 个节点的信息和角色。还有很多其他设置，这里省略。

```yaml
nodes:
  - address: 10.131.158.97
    user: ubuntu
    role: [controlplane, worker, etcd]
  - address: 10.131.158.194
    user: ubuntu
    role: [controlplane, worker, etcd]
  - address: 10.131.158.121
    user: ubuntu
    role: [controlplane, worker, etcd]
  - address: 10.131.158.133
    user: ubuntu
    role: [worker]
  - address: 10.131.158.247
    user: ubuntu
    role: [worker]
  - address: 10.131.158.166
    user: ubuntu
    role: [worker]

system-images:
    kubernetes: rancher/hyperkube:v1.18.2

services:
  etcd:
    snapshot: true
    creation: 6h
    retention: 24

ingress:
  provider: nginx
  options:
    use-forwarded-headers: 'true'
```

用该 yaml 文件作为参数运行 `rke` 命令即可创建 Kubernetes 环境。

```sh
rke_linux-amd64 up --config ./rancher_cluster.yaml
```

集群创建成功后，除了原始 yaml 文件外还会生成两个新文件。

```bash
$ ll
total 132K
-rw-r----- 1 wshi wshi 5.3K Jun  8 17:04 kube_config_rancher_cluster.yaml
-rw-r----- 1 wshi wshi 119K Jun  8 17:07 rancher_cluster.rkestate
-rw-rw-r-- 1 wshi wshi  748 Jun  8 16:53 rancher_cluster.yaml
```

其中 `kube_config_rancher_cluster.yaml` 是访问集群的配置文件，复制到 `~/kube/config` 后即可被 `kubectl` 读取。这样就能访问集群了。

```bash
$ kubectl get node
NAME             STATUS   ROLES                      AGE   VERSION
10.131.158.121   Ready    controlplane,etcd,worker   21h   v1.17.4
10.131.158.133   Ready    worker                     21h   v1.17.4
10.131.158.166   Ready    worker                     21h   v1.17.4
10.131.158.194   Ready    controlplane,etcd,worker   21h   v1.17.4
10.131.158.247   Ready    worker                     21h   v1.17.4
10.131.158.97    Ready    controlplane,etcd,worker   21h   v1.17.4
```

#### 在 Kubernetes 环境中安装 Rancher

按照 [rancher 官方文档](https://rancher.com/docs/rancher/v2.x/en/installation/k8s-install/helm-rancher/) 安装。这里只列出安装步骤，详细设置请参考文档。

1. 安装 `helm`

   参考 [helm 官网](https://helm.sh/docs/intro/install/) 安装 `helm`

   ```bash
   sudo snap install helm --classic
   ```

2. 给 `helm` 添加 `rancher` 仓库

   这里选择 `stable`

   ```bash
   helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
   ```

3. 新建安装 `rancher` 用的 `namespace`

   名称必须为 `cattle-system`

   ```bash
   kubectl create namespace cattle-system
   ```

4. 安装 `cert-manager`

   证书生成方式有多种，这里让 rancher 自动生成

   ```bash
   # Install the CustomResourceDefinition resources separately
   kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.0/cert-manager.crds.yaml

   # Create the namespace for cert-manager
   kubectl create namespace cert-manager

   # Add the Jetstack Helm repository
   helm repo add jetstack https://charts.jetstack.io

   # Update your local Helm chart repository cache
   helm repo update

   # Install the cert-manager Helm chart
   helm install \
     cert-manager jetstack/cert-manager \
     --namespace cert-manager \
     --version v0.15.0
   ```

   检查 `cert-manager` 状态

   ```bash
   $ kubectl get pods --namespace cert-manager
   NAME                                       READY   STATUS    RESTARTS   AGE
   cert-manager-766d5c494b-9cmcq              1/1     Running   0          15s
   cert-manager-cainjector-6649bbb695-cfmxq   1/1     Running   0          15s
   cert-manager-webhook-68d464c8b-5bmjt       1/1     Running   0          15s
   ```

5. 安装 `rancher-server`

   使用 Rancher 自动生成的证书安装 `rancher-server`

   ```bash
   helm install rancher rancher-stable/rancher \
     --namespace cattle-system \
     --set hostname=rancher.my.org
   ```

   检查 `rancher-server` 状态

   ```bash
   $ kubectl get pod -n cattle-system -o wide
   NAME                       READY   STATUS    RESTARTS   AGE   IP          NODE             NOMINATED NODE   READINESS GATES
   rancher-756b996499-fjnt9   1/1     Running   0          35m   10.42.0.4   10.131.158.247   <none>           <none>
   rancher-756b996499-rkn8h   1/1     Running   0          35m   10.42.2.4   10.131.158.121   <none>           <none>
   rancher-756b996499-wmczg   1/1     Running   0          35m   10.42.5.4   10.131.158.97    <none>           <none>

   ```

   各节点上的 Pod 均为 `Running` 状态，说明安装成功。

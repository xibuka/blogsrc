---
title: 使用 Rancher 的 Continuous Delivery 功能轻松实现 GitOps
date: 2021-11-11T16:18:38+09:00
draft: false
tags: 
- Rancher
- Fleet
---

本文将搭建一个单节点 Rancher server 和两个 k3s 集群环境，并通过 Rancher 的 Continuous Delivery 功能，用 GitOps 操作这两个 k3s 集群。

## Step 1: 部署 Rancher Server

首先在 rancher 节点上执行如下 docker 命令，搭建单节点 Rancher server。

```ctr:rancher
sudo docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  --privileged \
  rancher/rancher:v2.5.10
```

Rancher server 大约 1 分钟后启动，使用浏览器访问 rancher 节点的 IP 地址即可进入 Rancher UI。

本例中 Rancher 使用自签名证书，浏览器会弹出证书警告，可以直接跳过。有些浏览器没有跳过按钮，此时点击错误页面任意位置并输入 `thisisunsafe`，即可跳过警告并接受证书。

首次访问时需要设置初始密码，按页面提示操作即可。

## Step 2: 部署 k3s Kubernetes 集群

接下来部署 k3s 集群。方法很简单，只需在 k3s-1 和 k3s-2 节点分别执行如下命令。

为了后续演示升级，这里特意指定了较旧的 k3s 版本。

### k3s-1

```bash
sudo curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.19.15+k3s2 sh -
```

### k3s-2

```bash
sudo curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.19.15+k3s2 sh -
```

部署完成后，用如下命令检查集群：

```bash
sudo kubectl get node
```

注意：K3s 默认以 `root` 用户操作，因此需要 `sudo` 权限。

## Step 3: 将 k3s 集群导入 Rancher

接下来将 k3s 集群导入 Rancher。以 k3s-1 为例，操作如下：

1. 在 Rancher Global 页面右侧点击 `Add Cluster`，选择 `Other Cluster`。![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lf9ujojj31km0iawgw.jpg)![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lho6paqj31ks0n4tbo.jpg)
2. Cluster Name 填写 `k3s-1`，点击 `Create`。
3. 点击以 `curl...` 开头的命令，在 k3s-1 节点执行。![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0li59ccij311t0u0wjw.jpg)

k3s-2 也用同样方法注册。

## Step 4: 集群分组（Cluster Group）

现在开始使用 Continuous Delivery。在 Global 页面选择 `Tools` -> `Continuous Delivery`。

首先创建 `Cluster Group`。左侧菜单进入 `Cluster Group`，右侧点击 `Create`，进入创建页面。![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0litcf2xj31l80jm76u.jpg)

本例用 `k3s` 做演示，Name 填 `k3s-demo`。

接下来是关键步骤。`Cluster Group` 通过标签选择集群，点击 `Add Rule` 设置标签。本例用 K3s，`Cluster Selectors` 填 `k3s=true`。

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0ljfi55gj311g0u00ve.jpg)

设置完成后点击 `Create`，完成分组创建。

------

然后将两个已导入的 k3s 集群分配到该 `Cluster Group`。左侧菜单进入 `Clusters`，点击 `k3s-1` 右侧的︙，选择 `Assign to`。![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lk1pfikj31fx0u0tc8.jpg)

点击 `Add/Set Label`，设置标签 `k3s=true`，点击 `Apply`。这样该集群就分配到刚创建的分组了。![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lkuljntj31l80ls40e.jpg)

k3s-2 也同样操作。`Cluster Groups` 页面 `Clusters Ready` 应为 2。![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0llk63cvj31dt0u0dk3.jpg)

## Step 5: 配置 Git Repos

本步骤设置要引用的 `Git Repo`。左侧菜单进入 `Git Repos`，右侧点击 `Create` 进入创建页面。![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lna46oqj31lm0j4mzo.jpg) 输入名称后，用自己的 Github 账号 fork `https://github.com/rancher/fleet-examples`，并将 Repository URL（如 `https://github.com/xibuka/fleet-examples.git` ）填入。`Paths` 填 `/single-cluster/manifests`，即 `guest-book` 定义文件所在目录。然后设置部署目标，`Deploy To` 选择刚创建的 `Cluster Group`，点击 `Create`。

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lnq6olrj30u010jdiu.jpg)

这样 `guest-book` 资源就会部署到 k3s-1 和 k3s-2。![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lorwtfdj31si0jujut.jpg)

------

接下来在 deployment 目录下新增 `nginx.yaml` 文件。添加如下内容后，Continuous Delivery 会自动检测并部署到 `Cluster Group`。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 32000
```

部署完成后，在集群侧检查 `Pod` 和 `Service`。![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lpcvw6rj31sc0jg0w4.jpg) ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lqbftl3j31mz0u0grg.jpg)

同理，监控文件有变更时，也会自动部署到 `cluster group`。可以试着将上面 YAML 的如下两行修改：

```yaml
...
        image: nginx:1.20
...
    nodePort: 31000
```

变更会被自动同步。

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lqvplo3j31s20i0dj4.jpg)

## Step 6: 部署应用

本步骤注册 Git Repo 并部署 Rancher 应用。

Repository URL 填 `https://github.com/xibuka/core-bundles.git`，`Add Path` 添加如下两个路径：

- /longhorn
- /longhorn-crd ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lrrgmr1j30zz0u0gog.jpg)

点击 `Create`，定义的应用即会部署。

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lsbl6bnj31sc0nkaem.jpg) ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lsl6bt5j31si0gaq4v.jpg)

## Step 7: 升级

本步骤注册 Git Repo 并升级两个 k3s 集群。升级用到如下 Automated Upgrades 功能：

[ttps://rancher.com/docs/k3s/latest/en/upgrades/automated/](https://rancher.com/docs/k3s/latest/en/upgrades/automated/)

首先准备所需资源。分别在每个集群上依次执行如下命令：

```bash
sudo kubectl apply -f https://github.com/rancher/system-upgrade-controller/releases/download/v0.6.2/system-upgrade-controller.yaml
sudo kubectl apply -f https://github.com/rancher/system-upgrade-controller/releases/download/v0.6.2/system-upgrade-controller.yaml
```

然后 fork `https://github.com/xibuka/k3s-upgrade-plan` 并配置 Git repos。Branch Name 设为 `Main`，点击 `Create`。`/` 下所有内容都会被同步，无需额外添加 path。![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lt2yhh2j313l0u077f.jpg)

确认当前 k3s 版本为 1.21.5+k3s2。![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lu2ele4j31s00hmwhk.jpg)

将 Git Repos 中 Plan 文件的 version 改为 `1.22.2+k3s1` 并提交。稍等片刻，两个 k3s 集群会自动升级到 1.22.2。

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0luf74qvj31sk0qqtdd.jpg) ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lugbm2yj31ry0i4q5w.jpg)

Fleet Demo 到这里就结束了，Rancher 还有很多强大功能，欢迎继续探索！

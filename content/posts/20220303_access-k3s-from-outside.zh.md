---
title: "外部访问 K3s 集群的方法"
date: 2022-03-03T23:49:19+09:00
draft: false
---

## 从外部访问 k3s 集群

当你用默认设置创建 k3s 集群时，只能在本节点内部访问。
如果将 `/etc/rancher/k3s/k3s.yaml` kubeconfig 文件拷贝到其他主机并导入，尝试访问时会遇到如下报错：

```bash
❯ kubectl get node
Unable to connect to the server: x509: certificate is valid for 10.0.140.68, 10.43.0.1, 127.0.0.1, not xxx.xxx.xxx.xxx
```

要让 k3s 集群支持外部访问，可以在创建集群时加上如下参数：

```bash
--tls-san value                            (listener) Add additional hostname or IP as a Subject Alternative Name in the TLS cert
```

该参数详情见 <https://rancher.com/docs/k3s/latest/en/installation/install-options/#registration-options-for-the-k3s-server>

安装命令示例：

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san <your node public ip address>" sh -
```

然后将 `/etc/rancher/k3s/k3s.yaml` 的内容复制到本地，并把 server 的 IP 地址从 `127.0.0.1` 改为你实际要访问的地址。

再次获取集群信息时就可以正常访问了。

```bash
❯ kubectl get node
NAME         STATUS   ROLES                  AGE   VERSION
wenhan-dev   Ready    control-plane,master   61s   v1.22.7+k3s1
```

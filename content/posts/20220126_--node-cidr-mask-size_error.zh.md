---
title: "--node-cidr-mask-size 错误的原因与修复"
date: 2022-01-26T11:33:00+09:00
draft: false
tags: 
- Rancher
- RKE
---

在调整 rke 集群的 CIDR 时，遇到了如下报错，导致集群创建失败：

```log
{"log":"F1203 01:36:22.168496  1 node_ipam_controller.go:115] Controller: Invalid --cluster-cidr, mask size of cluster CIDR must be less than or equal to --node-cidr-mask-size configured for CIDR family\n","stream":"stderr","time":"2021-12-03T01:36:22.16859524Z"}
```

cluster.yaml 相关配置如下：

```yaml
services:
  kube-controller:
    cluster_cidr: 10.42.0.0/25
    service_cluster_ip_range: 10.43.0.0/25
  kube-api:
    service_cluster_ip_range: 10.43.0.0/25
```

问题出在 CIDR 的掩码大小。该掩码由 `--node-cidr-mask-size` 参数设置，必须大于（即 IP 范围更小）集群 CIDR 的掩码。默认值为 `24`，而上述配置为 `25`，比默认值大（IP 范围溢出），因此报错。

可以通过如下方式在 `extra_args` 中修改 `--node-cidr-mask-size`：

```yaml
services:
    kube-controller:
      cluster_cidr: 10.42.0.0/25
      service_cluster_ip_range: 10.43.0.0/25
      extra_args:
        node-cidr-mask-size: 25
```

设置为 `25`、`26` 等数字后，集群即可正常创建。

关于掩码大小与每个节点可用 Pod 数的关系：考虑到 Pod 的增删，实际可用的 Pod 数大约是分配 IP 数的一半。

例如，cluster_cidr 掩码为 `25` 时，集群级别的 IP 数为 `128`。

单节点时，`--node-cidr-mask-size` 也设为 25，则分配 `128` 个 IP，可创建约 `33`～`64` 个 Pod。

三节点时，每个节点最多可用 IP 为 `42`，此时需将 `--node-cidr-mask-size` 设为 `27`，可用 Pod 数约为 `9`～`16`。
系统级 Pod（如 coredns）也有约 `10` 个，如果设为 `28`，业务 Pod 的 IP 就不够用了。

此外，还需相应设置 max-pods：

```yaml
    kubelet:
      extra_args:
        max-pods: 40
```

参考：
[https://cloud.google.com/kubernetes-engine/docs/how-to/flexible-pod-cidr](https://cloud.google.com/kubernetes-engine/docs/how-to/flexible-pod-cidr)

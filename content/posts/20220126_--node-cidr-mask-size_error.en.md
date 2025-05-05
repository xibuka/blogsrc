---
title: "Cause and Fix for --node-cidr-mask-size Error"
date: 2022-01-26T11:33:00+09:00
draft: false
tags: 
- Rancher
- RKE
---

When I changed the CIDR of an rke cluster, I encountered the following error and the cluster creation failed.

```log
{"log":"F1203 01:36:22.168496  1 node_ipam_controller.go:115] Controller: Invalid --cluster-cidr, mask size of cluster CIDR must be less than or equal to --node-cidr-mask-size configured for CIDR family\n","stream":"stderr","time":"2021-12-03T01:36:22.16859524Z"}
```

The relevant part of cluster.yaml is as follows:

```yaml
services:
  kube-controller:
    cluster_cidr: 10.42.0.0/25
    service_cluster_ip_range: 10.43.0.0/25
  kube-api:
    service_cluster_ip_range: 10.43.0.0/25
```

The problematic part is the mask size of the CIDR. This mask size is set by `--node-cidr-mask-size` and must be greater (i.e., a smaller IP range) than the cluster CIDR mask size. The default is `24`, so the above setting of `25` is larger (i.e., the IP range overflows), resulting in an error.

You can change this `--node-cidr-mask-size` using `extra_args` as shown below:

```yaml
services:
    kube-controller:
      cluster_cidr: 10.42.0.0/25
      service_cluster_ip_range: 10.43.0.0/25
      extra_args:
        node-cidr-mask-size: 25
```

If you set it to numbers like `25` or `26`, the cluster can be created successfully.

Regarding the relationship between this mask size and the number of Pods available per node: considering Pod addition/removal, about half of the reserved IP addresses can actually be used for Pods.

For example, with a cluster_cidr mask of `25`, the cluster-level IP address count is `128`.

For a single node, if you also set `--node-cidr-mask-size` to 25, `128` IP addresses are reserved, and you can create about `33` to `64` Pods.

For three nodes, the number of IPs per node is up to `42`, so you need to set `--node-cidr-mask-size` to `27`. In that case, the number of Pods is about `9` to `16`.
There are also about `10` system-level Pods (like coredns), so if you set it to `28`, there won't be enough IP addresses for business Pods.

Also, you need to set max-pods accordingly.

```yaml
    kubelet:
      extra_args:
        max-pods: 40
```

For reference:
[https://cloud.google.com/kubernetes-engine/docs/how-to/flexible-pod-cidr](https://cloud.google.com/kubernetes-engine/docs/how-to/flexible-pod-cidr)

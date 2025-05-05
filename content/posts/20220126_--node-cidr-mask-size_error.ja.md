---
title: "--node-cidr-mask-sizeエラーの原因と修正"
date: 2022-01-26T11:33:00+09:00
draft: false
tags: 
- Rancher
- RKE
---
rkeクラスタのcidrを弄ったら、以下のようなエラーが出てクラスタの作成が失敗した。

```log
{"log":"F1203 01:36:22.168496  1 node_ipam_controller.go:115] Controller: Invalid --cluster-cidr, mask size of cluster CIDR must be less than or equal to --node-cidr-mask-size configured for CIDR family\n","stream":"stderr","time":"2021-12-03T01:36:22.16859524Z"}
```

cluster.yamlの関連部分は以下のようになっています。

```yaml
services:
  kube-controller:
    cluster_cidr: 10.42.0.0/25
    service_cluster_ip_range: 10.43.0.0/25
  kube-api:
    service_cluster_ip_range: 10.43.0.0/25
```

問題になる場所はCIDRのマスクサイズです。このマスクサイズは`--node-cidr-mask-size`で設定され、クラスタのCIDRのマスクサイズより大きく（IP範囲が少なく）なる必要があります。デフォルトは`24`のため、上記の設定の`25`より小さい（IP範囲が溢れた）のでエラーとなりました。

この`--node-cidr-mask-size`は、以下のように`extra_args`で変更することができます。

```yaml
services:
    kube-controller:
      cluster_cidr: 10.42.0.0/25
      service_cluster_ip_range: 10.43.0.0/25
      extra_args:
        node-cidr-mask-size: 25
```

`25`, `26`のような数字に設定したら、クラスタの作成ができるようになります。

このマスクサイズとノードあたりで利用できるPod数の関係として、Pod の追加 / 削除などを考慮し、確保したIPアドレスの数の半分ぐらいが実際に作成できるPodの数となります。

例えば、cluster_cidrのマスクが`25`なので、クラスタレベルのIPアドレス数は`128`個です。

1ノードの場合、`--node-cidr-mask-size`を同じく25を設定したら`128`個のIPアドレスが確保され、`33`～`64`のPodが作成できます。

3ノードの場合、ノードあたりのIP数は`42`個までしか使えなくて、`--node-cidr-mask-size`を`27`に設定しなければいけません。そうすると、Pod数は `9`～`16`になります。
システムレベルのPod（corednsなど）も`10`個程度あるので、`28`にしたら業務Pod用のIPアドレスが足りなくなります。

また、上記にあわせてmax-podsの設定も必要です。

```yaml
    kubelet:
      extra_args:
        max-pods: 40
```

参考まで
[https://cloud.google.com/kubernetes-engine/docs/how-to/flexible-pod-cidr](https://cloud.google.com/kubernetes-engine/docs/how-to/flexible-pod-cidr)

---
title: OpenShiftのコンテナ/Pod内でIPv6を無効化する方法
date: 2018-02-01 15:46:56
tags:
- Container
- OpenShift
---

OpenShiftのコンテナ/PodはIPv4プロトコルでデータを転送するため、通常はIPv6の設定を気にする必要はありません。しかし、場合によっては他のコンテナ/PodやホストOSに影響を与えず、コンテナ内だけでIPv6を無効化したいことがあります。

以下は、コンテナから出力されたIPv6情報の例です。

```zsh
[root@ocp37 ~]# oc exec django-ex-4-6gmsj -- ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
3: eth0@if45: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP 
    link/ether 0a:58:0a:80:00:24 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.128.0.36/23 brd 10.128.1.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::a4e3:f9ff:fe55:61db/64 scope link 
       valid_lft forever preferred_lft forever
```

セキュリティ上の理由から、コンテナ内で `sysctl -w` を実行してカーネルパラメータを変更することはできません。

```zsh
[root@ocp37 ~]# oc exec django-ex-4-6gmsj -- sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl: setting key "net.ipv6.conf.all.disable_ipv6": Read-only file system
command terminated with exit code 255
```

そのため、DeploymentConfigのKubernetes設定を変更する必要があります。Sysctl設定はKubernetes経由で公開されており、ユーザーはコンテナ内の名前空間ごとに特定のカーネルパラメータをランタイムで変更できます。名前空間化されたsysctlのみがPodごとに個別に設定可能です。
名前空間化されたsysctlについては[こちら](https://docs.openshift.com/container-platform/3.7/admin_guide/sysctls.html#namespaced-vs-node-level-sysctls)を参照してください。

手順は以下の通りです：

1. `/etc/origin/node/node-config.yaml` の kubeletArguments フィールドに以下を追加し、Unsafe Sysctlsを有効化します。

   ```zsh
   kubeletArguments:
     experimental-allowed-unsafe-sysctls:
       - net.ipv6.conf.all.disable_ipv6
   ```

2. ノードサービスを再起動して設定を反映させます：

   ```zsh
   systemctl restart atomic-openshift-node
   ```

3. 対象PodのDeploymentConfigを編集します。

   ```zsh
   oc edit dc/<対象PodのDeploymentConfig名>
   ```

4. templateフィールド内のmetadataに以下を追加し、保存して終了します（annotationsフィールドがなければ作成してください）。

   ```zsh
   spec:
     ....
     template:
       metadata:
         annotations:
           security.alpha.kubernetes.io/unsafe-sysctls: net.ipv6.conf.all.disable_ipv6=1
   ```

5. この更新済みDeploymentConfigで新しいコンテナ/Podをデプロイします。

   ```zsh
   oc deploy dc/<対象PodのDeploymentConfig名>  --latest
   ```

6. Podが起動したら、IPv6が無効化されていることを確認します。

   ```zsh
   [root@ocp37 ~]# oc exec django-ex-2-22znd -- ip a
   1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1
       link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
       inet 127.0.0.1/8 scope host lo
          valid_lft forever preferred_lft forever
   3: eth0@if41: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP
       link/ether 0a:58:0a:80:00:20 brd ff:ff:ff:ff:ff:ff link-netnsid 0
       inet 10.128.0.32/23 brd 10.128.1.255 scope global eth0
          valid_lft forever preferred_lft forever
   ```

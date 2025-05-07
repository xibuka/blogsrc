---
title: 如何在OpenShift的容器/Pod内禁用IPv6
date: 2018-02-01 15:46:56
tags:
- Container
- OpenShift
---

虽然OpenShift中的容器/Pod通过IPv4协议传输数据，通常无需关心IPv6的设置，但有时我们希望只在容器内禁用IPv6，而不影响其他容器/Pod或主机系统。

下面是容器中输出的IPv6信息示例：

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

出于安全考虑，容器内无法通过 `sysctl -w` 修改内核参数。

```zsh
[root@ocp37 ~]# oc exec django-ex-4-6gmsj -- sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl: setting key "net.ipv6.conf.all.disable_ipv6": Read-only file system
command terminated with exit code 255
```

因此，需要在DeploymentConfig中修改Kubernetes设置。Kubernetes通过sysctl设置允许用户在容器的命名空间内运行时修改部分内核参数。只有命名空间级别的sysctl可以在Pod内独立设置。
关于命名空间sysctl，详见[这里](https://docs.openshift.com/container-platform/3.7/admin_guide/sysctls.html#namespaced-vs-node-level-sysctls)。

操作步骤如下：

1. 在`/etc/origin/node/node-config.yaml`的kubeletArguments字段中添加如下内容，启用Unsafe Sysctls。

   ```zsh
   kubeletArguments:
     experimental-allowed-unsafe-sysctls:
       - net.ipv6.conf.all.disable_ipv6
   ```

2. 重启node服务以应用更改：

   ```zsh
   systemctl restart atomic-openshift-node
   ```

3. 编辑目标Pod的DeploymentConfig。

   ```zsh
   oc edit dc/<你的Pod的DeploymentConfig名称>
   ```

4. 在template字段下的metadata中添加如下设置后保存退出（如无annotations字段请新建）：

   ```zsh
   spec:
     ....
     template:
       metadata:
         annotations:
           security.alpha.kubernetes.io/unsafe-sysctls: net.ipv6.conf.all.disable_ipv6=1
   ```

5. 用更新后的DeploymentConfig部署新容器/Pod。

   ```zsh
   oc deploy dc/<你的Pod的DeploymentConfig名称>  --latest
   ```

6. Pod启动后，确认IPv6已被禁用。

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

---
title: How to disable IPv6 inside a container/pod in OpenShift
date: 2018-02-01 15:46:56
tags:
- Container
- OpenShift
---


Although the container/pod in OpenShift transfer data by IPv4 protocol, and you
do not need to worry about the setting of IPv6. But in some case people want to
disable IPv6 inside the container without effecting other container/pods or
host OS.

Here is an example of the IPv6 info outputed from a container.

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

It is not allowed to run ` sysctl -w ` to update a kernel parameter inside
a container for security.

```zsh
[root@ocp37 ~]# oc exec django-ex-4-6gmsj -- sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl: setting key "net.ipv6.conf.all.disable_ipv6": Read-only file system
command terminated with exit code 255
```

So what you need to do is to change the kubernetes settings in the DeploymentConfig. Sysctl settings are exposed via Kubernetes, allowing users to modify certain kernel parameters at runtime for namespaces within a container. Only sysctls that are namespaced can be set independently on pods;
For namespaced sysctl, please refer [here](https://docs.openshift.com/container-platform/3.7/admin_guide/sysctls.html#namespaced-vs-node-level-sysctls) for detail.

Here are the steps:

1. Add below setting to kubeletArguments field in the /etc/origin/node/node-config.yaml file. This will enable Unsafe Sysctls.

   ```zsh
   kubeletArguments:
     experimental-allowed-unsafe-sysctls:
       - net.ipv6.conf.all.disable_ipv6
   ```

2. Restart the node service to apply the changes:

   ```zsh
   systemctl restart atomic-openshift-node
   ```

3. Edit DeploymentConfig of the target pod.

   ```zsh
   oc edit dc/<DeploymentConfig of your pod>
   ```

4. Add below settings to the metadata filed inside of template filed, then save and quit. (You may need to create annotations filed if it is not exist.)

   ```zsh
   spec:
     ....
     template:
       metadata:
         annotations:
           security.alpha.kubernetes.io/unsafe-sysctls: net.ipv6.conf.all.disable_ipv6=1
   ```

5. Deploy a new container/pod using this updated DeploymentConfig

   ```zsh
   oc deploy dc/<DeploymentConfig of your pod>  --latest
   ```

6. When the pod is ready, confirm ipv6 is diabled.

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

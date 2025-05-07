---
title: '错误：容器创建失败：加载 raw.lxc 失败'
date: 2018-06-04 16:19:39
tags:
- Ubuntu
- MaaS
---

我参考了以下链接尝试安装和测试 MaaS：

[https://docs.maas.io/2.1/en/installconfig-lxd-install](https://docs.maas.io/2.1/en/installconfig-lxd-install)

在文档的 profile 编辑部分：

1. 执行 `lxc profile edit maas`
1. 将 config 后的 {} 替换为如下内容（不包括 config:）：

    ```yaml
    config:
      raw.lxc: |-
        lxc.cgroup.devices.allow = c 10:237 rwm
        lxc.apparmor.profile = unconfined
        lxc.cgroup.devices.allow = b 7:* rwm
      security.privileged: "true"
    ```

1. 在 launch 步骤遇到如下报错：

    ```sh
    $ lxc launch -p maas ubuntu:16.04 xenial-maas
    Creating xenial-maas
    Error: Failed container creation: Failed to load raw.lxc
    ```

这是因为我用的是 LXD 3.0，上述配置键已经过时。
根据[这个评论](https://github.com/lxc/lxd/issues/4393#issuecomment-378181793)，lxd 2.1 之后 `lxc.aa_profile` 改成了 `lxc.apparmor.profile`。

所以解决方法如下：

1. 再次执行 `lxc profile edit maas`
1. 将 `lxc.aa_profile` 替换为 `lxc.apparmor.profile`

    ```yaml
    config:
      raw.lxc: |-
        lxc.cgroup.devices.allow = c 10:237 rwm
        lxc.apparmor.profile = unconfined
        lxc.cgroup.devices.allow = b 7:* rwm
      security.privileged: "true"
    ```

1. 重新运行 launch 命令

    ```sh
    $ lxc launch -p maas ubuntu:16.04 xenial-maas
    Creating xenial-maas
    Starting xenial-maas
    ```

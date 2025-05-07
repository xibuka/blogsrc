---
title: 'Error: Failed container creation: Failed to load raw.lxc'
date: 2018-06-04 16:19:39
tags:
- Ubuntu
- MaaS
---

I follow below URL to try to install and test MaaS,

[https://docs.maas.io/2.1/en/installconfig-lxd-install](https://docs.maas.io/2.1/en/installconfig-lxd-install)

At the profile edit part, from above documents

1. `lxc profile edit maas`
1. replace the {} after config with the following (excluding config:):

    ```yaml
    config:
      raw.lxc: |-
        lxc.cgroup.devices.allow = c 10:237 rwm
        lxc.aa_profile = unconfined
        lxc.cgroup.devices.allow = b 7:* rwm
      security.privileged: "true"
    ```

1. At the launch step, I hit below issue,

    ```sh
    $ lxc launch -p maas ubuntu:16.04 xenial-maas
    Creating xenial-maas
    Error: Failed container creation: Failed to load raw.lxc
    ```

This is because I'm using LXD 3.0, and the configuration key above is old.
Depending on [this comment](https://github.com/lxc/lxd/issues/4393#issuecomment-378181793), `lxc.aa_profile` is changed to `lxc.apparmor.profile` from lxd 2.1.

So the workaround is

1. `lxc profile edit maas` again
1. replace the `lxc.aa_profile` with `lxc.apparmor.profile`

    ```yaml
    config:
      raw.lxc: |-
        lxc.cgroup.devices.allow = c 10:237 rwm
        lxc.apparmor.profile = unconfined
        lxc.cgroup.devices.allow = b 7:* rwm
      security.privileged: "true"
    ```

1. re-run the launch command

    ```sh
    $ lxc launch -p maas ubuntu:16.04 xenial-maas
    Creating xenial-maas
    Starting xenial-maas
    ```

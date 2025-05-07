---
title: cannot ssh to server as root
date: 2017-02-16 16:36:12
tags: 
- Linux
- sshd
---
This is a solution for the problem where you know the root password but cannot ssh as root.

Actually, there is a parameter in the sshd configuration file that controls whether root login is allowed.
On Linux, edit the configuration file /etc/ssh/sshd_config:

```/etc/ssh/sshd_config
PermitRootLogin no
```

Change it to:

```/etc/ssh/sshd_config
PermitRootLogin yes
```

Then restart sshd, and you will be able to access as root.

```bash
systemctl restart sshd
```

There is also a parameter to disable automatic login as shown below:

```yaml
PubkeyAuthentication no
```

You can also set individual settings for specific IP addresses:

```yaml
Match Address 172.25.0.11
    PubkeyAuthentication no
```

---
title: 无法以 root 用户 ssh 到服务器
date: 2017-02-16 16:36:12
tags: 
- Linux
- sshd
---
这是一个明明知道 root 密码却无法以 root 用户 ssh 登录服务器的解决方法。

实际上，sshd 的配置文件中有一个参数可以控制是否允许 root 登录。
在 Linux 环境下，编辑配置文件 /etc/ssh/sshd_config：

```/etc/ssh/sshd_config
PermitRootLogin no
```

将其修改为：

```/etc/ssh/sshd_config
PermitRootLogin yes
```

然后重启 sshd 服务，就可以用 root 登录了。

```sh
systemctl restart sshd
```

另外，还有如下参数可以关闭自动登录：

```yaml
PubkeyAuthentication no
```

也可以针对特定 IP 进行单独设置：

```yaml
Match Address 172.25.0.11
    PubkeyAuthentication no
```

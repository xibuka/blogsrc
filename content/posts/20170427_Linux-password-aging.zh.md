---
title: Linux 用户密码有效期管理
date: 2017-04-27 23:15:00
tags:
- Linux
---
本文介绍如何管理 Linux 用户密码的有效期（aging）。

![password aging](/img/master/passaging.png)

- last change (-d)：密码最后一次修改的天数
- min days   (-m)：密码可更改的最小天数
- max days   (-M)：密码必须更改的最大天数
- warn days  (-W)：密码即将过期时提前警告的天数
- password expiration date：密码过期日期
- inactive days (-l)：密码过期后账户保留的天数
- inactive date：账户变为非活动状态的日期

上述信息可以通过 chage 命令进行修改。

```bash
chage -m 0 -M 60 -W 7 -l 30
```

chage 命令的其他用法：

- 下次登录时强制用户修改密码

```bash
chage -d 0 username
```

- 显示当前设置

```bash
chage -l username
```

- 指定日期让账户过期

```bash
chage -E YYYY-MM-DD username
```

与用户账户相关的其他内容：

- 锁定和解锁账户

```bash
usermod -L username
usermod -U username
```

---
title: Managing Linux User Password Expiration
date: 2017-04-27 23:15:00
tags:
- Linux
---
This article explains how to manage user password expiration (aging) in Linux.

![password aging](/img/master/passaging.png)

- last change (-d): Days since the password was last changed
- min days   (-m): Minimum number of days before the password can be changed
- max days   (-M): Maximum number of days before the password must be changed
- warn days  (-W): Number of days before expiration to warn the user
- password expiration date: The date the password expires
- inactive days (-l): Number of days the account remains after the password expires
- inactive date: The date the account becomes inactive

You can change the above settings using the chage command.

```bash
chage -m 0 -M 60 -W 7 -l 30
```

Other useful chage command usages:

- Force password change at next login

```bash
chage -d 0 username
```

- Display current settings

```bash
chage -l username
```

- Set account to expire on a specific date

```bash
chage -E YYYY-MM-DD username
```

Other user account related commands:

- Lock and unlock accounts

```bash
usermod -L username
usermod -U username
```

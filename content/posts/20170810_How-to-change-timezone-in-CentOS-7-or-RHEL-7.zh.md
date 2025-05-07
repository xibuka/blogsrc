---
title: 如何在 CentOS 7 或 RHEL 7 中更改时区
date: 2017-08-10 14:18:08
tags:
- Linux
---

## 查看当前时区状态

```zsh
[root@rhel7 ~]# timedatectl
      Local time: Thu 2017-08-10 05:19:53 UTC
  Universal time: Thu 2017-08-10 05:19:53 UTC
        RTC time: Thu 2017-08-10 05:19:52
       Time zone: UTC (UTC, +0000)
     NTP enabled: yes
NTP synchronized: yes
 RTC in local TZ: no
      DST active: n/a
```

## 列出可用时区

```zsh
[root@rhel7 ~]# timedatectl list-timezones 
Asia/Aden
Asia/Almaty
Asia/Amman
Asia/Anadyr
Asia/Aqtau
Asia/Aqtobe
Asia/Ashgabat
...
...
...
Pacific/Rarotonga
Pacific/Saipan
Pacific/Tahiti
Pacific/Tarawa
Pacific/Tongatapu
Pacific/Wake
Pacific/Wallis
```

## 查找并设置你的时区

你可以用 grep 查找区域。

```zsh
[root@rhel7 ~]# timedatectl list-timezones | grep Tokyo
Asia/Tokyo
```

现在设置你的时区并检查

```zsh
[root@rhel7 ~]# timedatectl set-timezone Asia/Tokyo        
[root@rhel7 ~]# timedatectl 
      Local time: Thu 2017-08-10 14:22:37 JST
  Universal time: Thu 2017-08-10 05:22:37 UTC
        RTC time: Thu 2017-08-10 05:22:37
       Time zone: Asia/Tokyo (JST, +0900)
     NTP enabled: yes
NTP synchronized: yes
 RTC in local TZ: no
      DST active: n/a
[root@rhel7 ~]# date
Thu Aug 10 14:23:35 JST 2017
```

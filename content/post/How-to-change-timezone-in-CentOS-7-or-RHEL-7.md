---
title: How to change timezone in CentOS 7 or RHEL 7
date: 2017-08-10 14:18:08
tags:
- Linux
---

# check the current timezone status

```
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

<!-- more -->

# list the avaliable timezones

```
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

# find and set your timezone

You can grep for your area.
```
[root@rhel7 ~]# timedatectl list-timezones | grep Tokyo
Asia/Tokyo
```

Now set to your timezone and check

```
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



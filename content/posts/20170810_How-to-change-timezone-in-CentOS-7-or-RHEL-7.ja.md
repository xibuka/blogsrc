---
title: CentOS 7 または RHEL 7 でタイムゾーンを変更する方法
date: 2017-08-10 14:18:08
tags:
- Linux
---

## 現在のタイムゾーンの確認

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

## 利用可能なタイムゾーンの一覧表示

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

## タイムゾーンの検索と設定

エリアでgrep検索できます。

```zsh
[root@rhel7 ~]# timedatectl list-timezones | grep Tokyo
Asia/Tokyo
```

タイムゾーンを設定し、確認します。

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

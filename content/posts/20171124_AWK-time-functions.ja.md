---
title: AWK - 時刻関数
date: 2017-11-24 08:34:34
tags:
- Linux
- awk
---

`date`コマンド以外にも、awkには時刻変換に役立つ以下の組み込み関数があります。

## systime()

現在時刻をエポック（1970-01-01 00:00:00）からの秒数で返します。

```bash
$ awk 'BEGIN {
   print "Number of seconds since the Epoch = " systime()
}'
Number of seconds since the Epoch = 1511480989
```

## mktime(YYYY MM DD HH MM SS)

日付文字列 "YYYY MM DD HH MM SS" をエポックからの秒数に変換します。systimeと同じ形式の出力です。

```bash
$ awk 'BEGIN {
   print "Number of seconds since the Epoch = " mktime("2017 11 24 08 52 10")
}'
Number of seconds since the Epoch = 1511481130
```

## strftime()

指定したフォーマットでタイムスタンプを整形します。

```bash
$ awk 'BEGIN {
   print strftime("Time = %m/%d/%Y %H:%M:%S", systime())
}'
Time = 11/24/2017 08:54:15
```

AWKでサポートされている時刻フォーマットは以下の通りです：

```AWK
%a
ロケールの省略形の曜日名

%A
ロケールの完全な曜日名

%b
ロケールの省略形の月名

%B
ロケールの完全な月名

%c
ロケールの「適切な」日付と時刻表現（"C"ロケールでは 'A %B %d %T %Y'）

%C
現在の年の世紀部分（年を100で割って切り捨て）

d
月の日（01–31）

%D
'%m/%d/%y' と同等

%e
1桁の場合はスペースで埋めた月の日

%F
'%Y-%m-%d' と同等（ISO 8601日付形式）

%g
ISO 8601週番号の下2桁の年（00–99）

%G
ISO週番号の完全な年

%h
'%b' と同等

%H
時（24時間表記、00–23）

%I
時（12時間表記、01–12）

%j
年内通算日（001–366）

%m
月（01–12）

%M
分（00–59）

%n
改行文字（ASCII LF）

%p
ロケールのAM/PM表記

%r
ロケールの12時間表記時刻（"C"ロケールでは 'I:%M:%S %p'）

%R
'%H:%M' と同等

%S
秒（00–60）

%t
TAB文字

%T
'%H:%M:%S' と同等

%u
曜日（1–7、月曜=1）

%U
年の週番号（最初の日曜が週1、00–53）

%V
年の週番号（最初の月曜が週1、01–53、ISO 8601方式）

%w
曜日（0–6、日曜=0）

%W
年の週番号（最初の月曜が週1、00–53）

%x
ロケールの「適切な」日付表現（"C"ロケールでは 'A %B %d %Y'）

%X
ロケールの「適切な」時刻表現（"C"ロケールでは 'T'）

%y
年の下2桁（00–99）

%Y
完全な年（例：2015）

%z
タイムゾーンオフセット（'+HHMM'形式、例：RFC 822/1036ヘッダ用）

%Z
タイムゾーン名または略称

%Ec %EC %Ex %EX %Ey %EY %Od %Oe %OH
%OI %Om %OM %OS %Ou %OU %OV %Ow %OW %Oy
"代替表現"

%%
リテラルの'%'
```

参照：
[The GNU Awk User's Guide: Time Functions](https://www.gnu.org/software/gawk/manual/html_node/Time-Functions.html)
[AWK - Time Functions](https://www.tutorialspoint.com/awk/awk_time_functions.htm)

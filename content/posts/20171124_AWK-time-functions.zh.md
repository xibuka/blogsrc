---
title: AWK - 时间函数
date: 2017-11-24 08:34:34
tags:
- Linux
- awk
---

除了 `date`，awk 还内置了如下时间函数，可以帮助你解决时间转换问题。

## systime()

返回当前时间（自 Epoch 1970-01-01 00:00:00 起的秒数）。

```bash
$ awk 'BEGIN {
   print "Number of seconds since the Epoch = " systime()
}'
Number of seconds since the Epoch = 1511480989
```

## mktime(YYYY MM DD HH MM SS)

将日期字符串 "YYYY MM DD HH MM SS" 转换为自 Epoch 起的秒数。输出格式与 systime 相同。

```bash
$ awk 'BEGIN {
   print "Number of seconds since the Epoch = " mktime("2017 11 24 08 52 10")
}'
Number of seconds since the Epoch = 1511481130
```

## strftime()

根据指定格式格式化时间戳。

```bash
$ awk 'BEGIN {
   print strftime("Time = %m/%d/%Y %H:%M:%S", systime())
}'
Time = 11/24/2017 08:54:15
```

AWK 支持的时间格式如下：

```AWK
%a
本地缩写的星期名

%A
本地完整星期名

%b
本地缩写的月份名

%B
本地完整月份名

%c
本地"合适"的日期和时间表示（在 "C" locale 下为 'A %B %d %T %Y'）

%C
当前年份的世纪部分（年份除以100并向下取整）

%d
月份中的日（01–31）

%D
等价于 '%m/%d/%y'

%e
一位数时用空格填充的日

%F
等价于 '%Y-%m-%d'（ISO 8601 日期格式）

%g
ISO 8601 周编号的年份后两位（00–99）

%G
ISO 周编号的完整年份

%h
等价于 '%b'

%H
小时（24小时制，00–23）

%I
小时（12小时制，01–12）

%j
一年中的第几天（001–366）

%m
月份（01–12）

%M
分钟（00–59）

%n
换行符（ASCII LF）

%p
本地 AM/PM 表示

%r
本地 12 小时制时间（在 "C" locale 下为 '%I:%M:%S %p'）

%R
等价于 '%H:%M'

%S
秒（00–60）

%t
TAB 字符

%T
等价于 '%H:%M:%S'

%u
星期几（1–7，周一为1）

%U
一年中的第几周（以第一个周日为第一周，00–53）

%V
一年中的第几周（以第一个周一为第一周，01–53，ISO 8601）

%w
星期几（0–6，周日为0）

%W
一年中的第几周（以第一个周一为第一周，00–53）

%x
本地"合适"的日期表示（在 "C" locale 下为 'A %B %d %Y'）

%X
本地"合适"的时间表示（在 "C" locale 下为 '%T'）

%y
年份后两位（00–99）

%Y
完整年份（如2015）

%z
时区偏移（'+HHMM'格式，如 RFC 822/1036）

%Z
时区名或缩写

%Ec %EC %Ex %EX %Ey %EY %Od %Oe %OH
%OI %Om %OM %OS %Ou %OU %OV %Ow %OW %Oy
"替代表示"

%%
字面上的'%'
```

参考：
[The GNU Awk User's Guide: Time Functions](https://www.gnu.org/software/gawk/manual/html_node/Time-Functions.html)
[AWK - Time Functions](https://www.tutorialspoint.com/awk/awk_time_functions.htm)

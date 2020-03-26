---
title: AWK - time functions
date: 2017-11-24 08:34:34
tags:
- Linux
- awk
---

Apart of `date`, awk also has below built-in time functions which will help you
to resolve time convert problem

# systime()
This will return the current time as the number of seconds since the Epoch (1970-01-01 00:00:00). 

```
$ awk 'BEGIN {
>    print "Number of seconds since the Epoch = " systime()
> }'
Number of seconds since the Epoch = 1511480989
```

# mktime(YYYY MM DD HH MM SS)
This will convert date string "YYYY MM DD HH MM SS" to the number of seconds
since the Epoch. It is the same output with systime.

```
$ awk 'BEGIN {
   print "Number of seconds since the Epoch = " mktime("2017 11 24 08 52 10")
}'
Number of seconds since the Epoch = 1511481130
```

# strftime()
This will formats timestamps according to the specfification in format.

```
$ awk 'BEGIN {
>    print strftime("Time = %m/%d/%Y %H:%M:%S", systime())
> }'
Time = 11/24/2017 08:54:15
```

<!-- more -->

Below time formats are supported by AWK:

```
%a
The locale’s abbreviated weekday name.

%A
The locale’s full weekday name.

%b
The locale’s abbreviated month name.

%B
The locale’s full month name.

%c
The locale’s “appropriate” date and time representation. (This is ‘%A %B %d %T %Y’ in the "C" locale.)

%C
The century part of the current year. This is the year divided by 100 and truncated to the next lower integer.

%d
The day of the month as a decimal number (01–31).

%D
Equivalent to specifying ‘%m/%d/%y’.

%e
The day of the month, padded with a space if it is only one digit.

%F
Equivalent to specifying ‘%Y-%m-%d’. This is the ISO 8601 date format.

%g
The year modulo 100 of the ISO 8601 week number, as a decimal number (00–99). For example, January 1, 2012, is in week 53 of 2011. Thus, the year of its ISO 8601 week number is 2011, even though its year is 2012. Similarly, December 31, 2012, is in week 1 of 2013. Thus, the year of its ISO week number is 2013, even though its year is 2012.

%G
The full year of the ISO week number, as a decimal number.

%h
Equivalent to ‘%b’.

%H
The hour (24-hour clock) as a decimal number (00–23).

%I
The hour (12-hour clock) as a decimal number (01–12).

%j
The day of the year as a decimal number (001–366).

%m
The month as a decimal number (01–12).

%M
The minute as a decimal number (00–59).

%n
A newline character (ASCII LF).

%p
The locale’s equivalent of the AM/PM designations associated with a 12-hour clock.

%r
The locale’s 12-hour clock time. (This is ‘%I:%M:%S %p’ in the "C" locale.)

%R
Equivalent to specifying ‘%H:%M’.

%S
The second as a decimal number (00–60).

%t
A TAB character.

%T
Equivalent to specifying ‘%H:%M:%S’.

%u
The weekday as a decimal number (1–7). Monday is day one.

%U
The week number of the year (with the first Sunday as the first day of week one) as a decimal number (00–53).

%V
The week number of the year (with the first Monday as the first day of week one) as a decimal number (01–53). The method for determining the week number is as specified by ISO 8601. (To wit: if the week containing January 1 has four or more days in the new year, then it is week one; otherwise it is the last week [52 or 53] of the previous year and the next week is week one.)

%w
The weekday as a decimal number (0–6). Sunday is day zero.

%W
The week number of the year (with the first Monday as the first day of week one) as a decimal number (00–53).

%x
The locale’s “appropriate” date representation. (This is ‘%A %B %d %Y’ in the "C" locale.)

%X
The locale’s “appropriate” time representation. (This is ‘%T’ in the "C" locale.)

%y
The year modulo 100 as a decimal number (00–99).

%Y
The full year as a decimal number (e.g., 2015).

%z
The time zone offset in a ‘+HHMM’ format (e.g., the format necessary to produce RFC 822/RFC 1036 date headers).

%Z
The time zone name or abbreviation; no characters if no time zone is determinable.

%Ec %EC %Ex %EX %Ey %EY %Od %Oe %OH
%OI %Om %OM %OS %Ou %OU %OV %Ow %OW %Oy
“Alternative representations” for the specifications that use only the second letter (‘%c’, ‘%C’, and so on).57 (These facilitate compliance with the POSIX date utility.)

%%
A literal ‘%’.

If a conversion specifier is not one of those just listed, the behavior is undefined.58

For systems that are not yet fully standards-compliant, gawk supplies a copy of strftime() from the GNU C Library. It supports all of the just-listed format specifications. If that version is used to compile gawk (see Installation), then the following additional format specifications are available:

%k
The hour (24-hour clock) as a decimal number (0–23). Single-digit numbers are padded with a space.

%l
The hour (12-hour clock) as a decimal number (1–12). Single-digit numbers are padded with a space.

%s
The time as a decimal timestamp in seconds since the epoch.
```

refers : 
[The GNU Awk User&rsquo;s Guide: Time Functions](https://www.gnu.org/software/gawk/manual/html_node/Time-Functions.html)
[AWK - Time Functions](https://www.tutorialspoint.com/awk/awk_time_functions.htm)


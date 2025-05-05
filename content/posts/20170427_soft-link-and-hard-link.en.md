---
title: The Difference Between Soft Links and Hard Links
date: 2017-04-27 22:14:48
tags:
- Linux
---

A memo about the differences between soft links and hard links.
I will add more if I remember other points.

Item  | Soft Link           | Hard Link
------|---------------------| -------------
size  | 4 byte              | Same as the original file (displayed)
inode | Has a different inode from the original file | Shares the same inode as the original file
Limit | -                   | Must be on the same filesystem as the original file

You can see the difference in link size and inode number as shown below.

```bash
wenhanMBP:  /tmp/link
→ ls -li
total 1024
12807105 -rw-r--r--  1 shiwenhan  wheel  524288  4 27 22:18 file

wenhanMBP:  /tmp/link
→ ln file hardlink-to-file

wenhanMBP:  /tmp/link
→ ls -li
total 2048
12807105 -rw-r--r--  2 shiwenhan  wheel  524288  4 27 22:18 file
12807105 -rw-r--r--  2 shiwenhan  wheel  524288  4 27 22:18 hardlink-to-file

wenhanMBP:  /tmp/link
→ ln -s file softlink-to-file

wenhanMBP:  /tmp/link
→ ls -lih
total 2056
12807105 -rw-r--r--  2 shiwenhan  wheel   512K  4 27 22:18 file
12807105 -rw-r--r--  2 shiwenhan  wheel   512K  4 27 22:18 hardlink-to-file
12807448 lrwxr-xr-x  1 shiwenhan  wheel     4B  4 27 22:27 softlink-to-file -> file
```

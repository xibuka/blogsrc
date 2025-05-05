---
title: 软链接与硬链接的区别
date: 2017-04-27 22:14:48
tags:
- Linux
---

记录一下软链接和硬链接的区别。
如果以后想起其他点会再补充。

项目  | 软链接           | 硬链接
------|------------------| -------------
大小  | 4 字节           | 显示上与原文件相同
inode | 与原文件不同 inode | 与原文件相同 inode
限制  | -                | 必须在同一文件系统下

如下可以看到链接的大小和 inode 编号的区别。

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

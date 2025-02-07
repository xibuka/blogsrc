---
title: ソフトリンクとハードリンクの違い
date: 2017-04-27 22:14:48
tags:
- Linux
---

ソフトリンクとハードリンクの違いについてメモする
他にも思い出したらまた追記する。


項目  | ソフトリンク        | ハードリンク 
------|---------------------| -------------
size  | 4 byte              | 表示上元ファイルと同じ  
inode | 元ファイルと異なるinodeを持つ  | 元ファイルと同じinodeを持つ 
制限  | -                   | 元ファイルと同じファイルシステム上にある必要がある 

以下でリンクのサイズとinode番号の違いがわかるはず。



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

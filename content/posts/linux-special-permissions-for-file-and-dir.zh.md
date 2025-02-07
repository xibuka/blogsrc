---
title: Linux文件的特殊权限设置 setuid setgit sticky
date: 2017-05-03 01:17:17
tags:
- Linux
---

# 特殊权限对文件和文件夹的影响

Linux系统中存在三个比较特殊的权限，分别是setuid，setgid，和sticky。
下面的表显示了他们之间的区别和对文件及文件夹的影响。

权限种类      | 对文件的影响 | 对文件夹的影响。
--------------|------------------|-----------------
u+s(suid)     | 文件在自己的owner权限下执行，而并不是在执行这个文件的用户下执行。好处就是不管谁执行这个文件，环境变数等常量都可以统一为onwer的 | 无影响 
g+s(sgid)     | 跟setuid很像，文件执行时会在自己的group下执行。| 文件夹内新文件的group都会跟上层文件夹的group一致
o+t(sticky)   | 无影响         | 对文件夹有w权限的用户，仅允许更改和删除属于自己的文件。也就是owner是自己的文件。对其他用户的文件无法更改或删除。



# 特殊权限的设定。
用记号设定: setuid = u+s; setgid = g+s; sticky = o+t
用数字设定: setuid = 4;   setgid = 2;   sticky = 1

例
```
# chmod g+s file 
# chmod 1755 file
```

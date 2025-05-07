---
title: yum update失败及修复方法
date: 2018-02-18 16:46:33
tags:
- yum
- Linux
---

在我的 centOS 7 上运行 `yum update` 时遇到了错误，命令无法更新系统！

```bash
# yum update
Loaded plugins: fastestmirror
Determining fastest mirrors
 * base: centos.gbeservers.com
 * epel: linux.mirrors.es.net
 * extras: linux.mirrors.es.net
 * ius: hkg.mirror.rackspace.com
 * updates: mirror.atlantic.net
  File "/usr/libexec/urlgrabber-ext-down", line 28
    except OSError, e:
                  ^
SyntaxError: invalid syntax
  File "/usr/libexec/urlgrabber-ext-down", line 28
    except OSError, e:
                  ^
SyntaxError: invalid syntax
  File "/usr/libexec/urlgrabber-ext-down", line 28
    except OSError, e:
                  ^
SyntaxError: invalid syntax
  File "/usr/libexec/urlgrabber-ext-down", line 28
    except OSError, e:
                  ^
SyntaxError: invalid syntax
  File "/usr/libexec/urlgrabber-ext-down", line 28
    except OSError, e:
                  ^
SyntaxError: invalid syntax


Exiting on user cancel
```

看起来系统有点问题。查了一下，发现根本原因是 python 版本不匹配。'yum' 命令需要 `/usr/bin/python` 这个符号链接指向 python2.7，而我之前改成了 python3.6。

```bash
# head /usr/bin/yum
#!/usr/bin/python
import sys
try:
    import yum
except ImportError:
    print >> sys.stderr, """
There was a problem importing one of the Python modules
required to run yum. The error leading to this problem was:

   %s

# ll /usr/bin/python*
lrwxrwxrwx. 1 root root     9 Jul 27  2017 python -> python3.6
lrwxrwxrwx. 1 root root     9 Jul 26  2017 python2 -> python2.7
-rwxr-xr-x. 1 root root  7136 Nov  6  2016 python2.7
-rwxr-xr-x. 2 root root 11312 Apr  7  2017 python3.6
-rwxr-xr-x. 2 root root 11312 Apr  7  2017 python3.6m
```

解决方法是把 `/usr/bin/yum` 的第一行改成 python2。

```bash
#!/usr/bin/python2
```

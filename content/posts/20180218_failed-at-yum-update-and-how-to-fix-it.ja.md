---
title: yum update失敗時の対処法
date: 2018-02-18 16:46:33
tags:
- yum
- Linux
---

CentOS 7で`yum update`を実行した際、エラーが発生し、OSのアップデートに失敗しました。

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

どうやらシステムに問題があるようです。調べてみると、原因はPythonのバージョンの不一致でした。'yum'コマンドは`/usr/bin/python`のシンボリックリンクがpython2.7である必要がありますが、以前python3.6に変更していました。

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

対処法は、`/usr/bin/yum`の1行目をpython2に変更することです。

```bash
#!/usr/bin/python2
```

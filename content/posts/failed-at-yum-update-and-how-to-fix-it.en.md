---
title: failed at yum update and how to fix it
date: 2018-02-18 16:46:33
tags:
- yum
- Linux
---

I hit an error when running `yum update` on my centOS 7, the command failed
to update my OS!

```
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

Looks like something is wrong with the system. After some research, I notice
the root cause is the missmatch of python version. 'yum' command need python 2.7
on /usr/bin/python symbol link, which I changed to python 3.6 before. 

```
# head /usr/bin/yum
#!/usr/bin/python
import sys
try:
    import yum
except ImportError:
    print >> sys.stderr, """\
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

The workaround is to change the first line of `/usr/bin/yum` to use python2 

```
#!/usr/bin/python2
```

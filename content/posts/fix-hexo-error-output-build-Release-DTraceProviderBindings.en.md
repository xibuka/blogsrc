---
title: fix hexo error output './build/Release/DTraceProviderBindings'
date: 2017-04-21 00:56:19
tags: 
- Hexo
---

There is a noisy error message appears each time when I run hexo command

```sh
Error: Cannot find module './build/Release/DTraceProviderBindings'
```

It is just a trace error and doesn't stop my work, but , it was so NOISY and I
realy want to remove it.

From the follow links,
[https://github.com/hexojs/hexo/issues/1922](https://github.com/hexojs/hexo/issues/1922)
[https://github.com/yarnpkg/yarn/issues/1915](https://github.com/yarnpkg/yarn/issues/1915)

I know the root cause is because the dtrace-provider package.
And I don't use is at all, so I just want to uninstall it.

```sh
npm uninstall dtrace-provider -g
```

but as this package is related to hexo, it will not be removed...
you can still see it by follow commands

```sh
npm list | grep dtrace
```

OK, Let clean up the enviroment, by uninstall hexo-cli and dtrace-provider
both.

* NOTE: you must use sudo to run the command

```sh
sudo npm uninstall hexo-cli -g
sudo npm uninstall dtrace-provider -g
```

Next, Install the hexo-cli with --no-optional option, and check dtrace-provider
is not installed.

* NOTE: you must use sudo to run the command

```sh
sudo npm install hexo-cli --no-optional -g
```

Finially, the world become quiet again. :)

---
title: 修复 hexo 报错 './build/Release/DTraceProviderBindings'
date: 2017-04-21 00:56:19
tags:
- Hexo
---

每次运行 hexo 命令时都会出现一个烦人的报错：

```sh
Error: Cannot find module './build/Release/DTraceProviderBindings'
```

这只是一个追踪错误，不会影响实际操作，但实在太吵了，我很想去掉它。

参考以下链接：
[https://github.com/hexojs/hexo/issues/1922](https://github.com/hexojs/hexo/issues/1922)
[https://github.com/yarnpkg/yarn/issues/1915](https://github.com/yarnpkg/yarn/issues/1915)

发现根本原因是 dtrace-provider 包。
而我根本用不到它，所以只想卸载掉。

```sh
npm uninstall dtrace-provider -g
```

但由于这个包和 hexo 有关联，实际上不会被移除……
你可以用下面的命令看到它依然存在：

```sh
npm list | grep dtrace
```

那就清理环境，把 hexo-cli 和 dtrace-provider 都卸载掉。

* 注意：必须用 sudo 执行命令

```sh
sudo npm uninstall hexo-cli -g
sudo npm uninstall dtrace-provider -g
```

然后用 --no-optional 选项重新安装 hexo-cli，确认 dtrace-provider 没有被装上。

* 注意：必须用 sudo 执行命令

```sh
sudo npm install hexo-cli --no-optional -g
```

终于，世界又安静了:)

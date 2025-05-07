---
title: 在 Mac 上安装支持 python 的 vim8
date: 2017-04-15 00:50:08
tags: 
- VIM
---

今天配置了我的 Mac Pro 开发环境。
发现用 brew 安装带 python 支持的 VIM8 非常简单。
（比 cent 7 简单多了）

如果你有 brew，只需运行：

```bash
brew install --with-python vim
```

如果想同时支持 python3 和 python2，运行：

```bash
brew install --with-python --with-python3 vim
```

补充：在某些新版系统上，python2 需要用下面的命令：

```bash
brew install --with-python@2
```

你可能需要先删除旧的 vim 可执行文件：

```bash
rm -f /usr/local/bin/vim
```

然后重新链接 vim：

```bash
brew link --overwrite vim

```

搞定！尽情享受你的 vim 吧

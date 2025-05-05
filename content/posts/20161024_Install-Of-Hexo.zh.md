---
title: 安装 Hexo
date: 2016-10-24 23:15:49
tags: 
- Hexo
---
参考了这里的 URL，设置了 Hexo 博客。
[https://liginc.co.jp/web/programming/server/104594](https://liginc.co.jp/web/programming/server/104594)

安装过程中出现了如下错误：

``` bash
% hexo deploy
ERROR Deployer not found: github
```

参考 [https://github.com/hexojs/hexo/issues/1040](https://github.com/hexojs/hexo/issues/1040) 解决了。

``` bash
% npm install hexo-deployer-git --save
```

_config.yml 的 type 也要改成 git

``` _config.yml
deploy:
  type: git
```

还得学习 Markdown 语法……要做的事情真多~

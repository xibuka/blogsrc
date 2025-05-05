---
title: Install Hexo
date: 2016-10-24 23:15:49
tags: 
- Hexo
---
While referring to the URL here, I set up a Hexo blog.
[https://liginc.co.jp/web/programming/server/104594](https://liginc.co.jp/web/programming/server/104594)

During the installation, I encountered the following error:

``` bash
% hexo deploy
ERROR Deployer not found: github
```

I fixed it by referring to [https://github.com/hexojs/hexo/issues/1040](https://github.com/hexojs/hexo/issues/1040).

``` bash
% npm install hexo-deployer-git --save
```

Also, change the type in _config.yml to git

``` _config.yml
deploy:
  type: git
```

I also need to study Markdown syntax... So much to do~

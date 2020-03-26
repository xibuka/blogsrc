---
title: Hexoをインストール
date: 2016-10-24 23:15:49
tags: 
- Hexo
---
ここのURLを参考しながら、HexoのBlogを設定した。
	https://liginc.co.jp/web/programming/server/104594

Install の途中で、以下のエラーが出た。

``` bash
% hexo deploy
ERROR Deployer not found: github
```
https://github.com/hexojs/hexo/issues/1040 を参考にして、直した。

``` bash
% npm install hexo-deployer-git --save
```

_config.ymlのtypeもgitに変更
``` _config.yml
deploy:
  type: git
```
<!-- more -->

MarkDownの文法も勉強せねばな。。。やることが多い〜

---
title: "从 Hexo 迁移到 Hugo"
date: 2020-03-30T14:07:21+09:00
draft: false
---

## 从 Hexo 迁移到 Hugo

之前一直用 Hexo 写博客，后来在学习 Golang 的时候顺便把博客迁移到了 Hugo。
原因有很多，主要有以下几点：

1. Hexo 依赖多个模块，有时候安装会出错。
2. 相比之下，Hugo 只需要一个二进制文件就够了。
3. 生成 HTML 文件的速度，Hugo 明显比 Hexo 快很多。

关于 Hugo 的安装和使用方法这里就不赘述了，这篇文章主要整理一下这次博客迁移过程中遇到的问题。

### 标签的写法

Hexo 下可以用如下格式写标签，但在 Hugo 下不行：

```conf
tag: Python
```

统一用下面这种格式就没问题了：

```conf
tags:
- Python
```

### 博客 md 文件的保存位置

这个因主题而异。我用的是 Even 主题，所以是在 post 目录下。

### 生成的博客页面与 Github Action 的集成

Hexo 可以用 `deploy` 子命令直接推送到 Github，但 Hugo 不行。
虽然有 `Hugo deploy` 命令，但主要是面向 AWS、GCE、Azure 等云平台：
[https://gohugo.io/hosting-and-deployment/hugo-deploy/](https://gohugo.io/hosting-and-deployment/hugo-deploy/)

所以需要手动将生成的文件推送到 Github Pages 仓库。
生成的博客页面都在 `public` 目录下。
如果用 Github Action，可以实现全自动化：写好新文章并 push 后，上述流程都能自动完成。
具体做法会在下一篇文章中总结。

## https 支持

虽然和 Hugo 没直接关系，但我顺便用 CloudFlare 实现了 https 支持。

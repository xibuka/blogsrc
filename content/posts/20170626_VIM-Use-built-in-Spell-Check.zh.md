---
title: '[VIM] 利用内置拼写检查功能'
date: 2017-06-26 16:37:57
tags:
- VIM
---
从第7版开始，VIM 内置了拼写检查功能，但默认是关闭的。

## 启用/禁用

可以使用 `:set spell` 和 `:set nospell` 来启用或禁用拼写检查。拼写检查不仅支持英语，也支持其他语言。用 `:echo &spelllang` 可以确认当前目标语言。用 `:set spelllang=en_GB.UTF-8` 可以切换目标语言，也可以用 `set spelllang=en_us,nl,medical` 设置多个语言。

## 拼写检查

用 `]s` 跳转到下一个拼写错误，用 `[s` 跳转到上一个拼写错误。

## 修正拼写错误

用 `z=` 列出拼写错误的建议，输入数字选择。

对于特殊单词，可以用 `zg` 添加到用户词典，用 `zw` 删除。

## 总结

| command      | action     |
| ------------ | ---------- |
| :set spell   | 启用拼写检查 |
| :set nospell | 禁用拼写检查 |
| ]s           | 跳到下一个错误 |
| [s           | 跳到上一个错误 |
| z=           | 列出建议 |
| zg           | 添加单词      |
| zw           | 删除单词      |

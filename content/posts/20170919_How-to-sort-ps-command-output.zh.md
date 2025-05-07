---
title: 如何对ps命令输出进行排序
date: 2017-09-19 14:11:37
tags:
- Linux
---

ps命令有一个`--sort`选项，可以帮助你对进程进行排序。

```bash
--sort spec
       指定排序顺序。排序语法为
       [+|-]key[,[+|-]key[,...]]。key请参考STANDARD FORMAT SPECIFIERS部分。"+"可省略，默认是升序（数值或字典序）。等同于k。例如：ps jax --sort=uid,-ppid,+pid
```

### 按内存排序ps输出

#### 内存使用从高到低

最大值在命令输出顶部

```bash
ps aux --sort -rss
```

#### 内存使用从低到高

最大值在命令输出底部

```bash
ps aux --sort rss
```

### 按CPU使用率排序ps输出

#### CPU使用率从高到低

最大值在命令输出顶部

```bash
ps aux --sort -pcpu
```

#### CPU使用率从低到高

最大值在命令输出底部

```bash
ps aux --sort rss
```

### 其他排序关键字

请查阅ps命令的man手册。

```man
STANDARD FORMAT SPECIFIERS
       这里列出了可用于控制输出格式（如-o选项）或用GNU风格--sort选项排序的关键字。

       例如：ps -eo pid,user,args --sort user

       该版本ps会尽量识别其他实现中常用的关键字。

       args, cmd, comm, command, fname, ucmd, ucomm, lstart, bsdstart, start等关键字可能包含空格。
       有些关键字可能无法用于排序。

       CODE        HEADER    说明

       %cpu        %CPU      进程的CPU利用率（##.#格式）。当前为cputime/realtime比率（%）。
                             不一定加起来为100%（pcpu别名）。

       %mem        %MEM      进程常驻集大小与物理内存的比率（%）。(pmem别名)

       ...（省略，详见man手册）...
```

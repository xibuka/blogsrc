---
title: 如何在注销后让进程继续运行
date: 2017-06-29 14:31:14
tags:
- Linux
- tmux
---
tmux 是一个开源软件，可以帮你实现这个需求。tmux 还有很多其他功能，这里只介绍如何让进程在 ssh 断开后依然运行。步骤如下：

1. 在 shell 中输入 ```tmux``` 启动一个 tmux 会话。
1. 在 tmux 会话中启动你的进程或脚本。
1. 按下 ```Ctrl+b``` 然后按 ```d```，即可离开（detach）tmux 会话。

现在你可以安全地注销或断开 ssh 连接，你的进程/脚本依然在 tmux 会话中运行。想要查看进程状态时，重新登录后输入 ```tmux attach``` 即可重新连接会话。

当前运行的会话可以用 ```tmux list-sessions``` 查看。

tmux 还有更多功能，详细用法请参考 ```man tmux```。

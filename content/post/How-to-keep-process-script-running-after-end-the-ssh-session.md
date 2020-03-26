---
title: How to keep process running after log off
date: 2017-06-29 14:31:14
tags:
- Linux
- tmux
---
tmux is an opensource software that can help you to do this. There are a lot of
other things tmux can do, but now let me explain how to keep process running
even end the ssh session. Please follow the steps:

1. start a tmux session by input ```tmux``` to the shell.
1. start your process or script inside the tmux session.
1. leave(detach) the tmux session by input ```Ctrl+b``` and then ```d```.

Now you can log off or terminate the ssh session safely, your process/script is
still running inside the tmux session. Once you want to check the status of
your process/script, you can login ang input ``` tmux attach ``` to re-attach
the session.

Currently running sessions can be listed by ```tmux list-sessions```.

tmux can do much more things, for more details about this command please have a
look at ```man tmux```.

---
title: 如何在VIM中复制文本到系统剪贴板
date: 2017-07-04 11:44:42
tags:
- VIM
---

1. 确认你的VIM已启用+clipboard功能
1. 在.vimrc中添加"set clipboard=unnamedplus"

## 检查+clipboard是否启用

```zsh
$ vim --version | grep clipboard
+clipboard       +job             +path_extra      +user_commands
+eval            +mouse_dec       +statusline      +xterm_clipboard
```

如果显示'-clipboard'，你需要带此功能重新编译VIM。

```zsh
$ git clone https://github.com/vim/vim.git
$ cd vim/src/
$ ./configure --with-features=huge                                    \
             --enable-multibyte                                       \
             --enable-rubyinterp=yes                                  \
             --enable-pythoninterp=yes                                \
             --with-python-config-dir=/usr/lib64/python2.7/config     \
             --enable-perlinterp=yes                                  \
             --enable-luainterp=yes                                   \
             --prefix=/usr/local/                                     \
             --enable-fail-if-missing                                 \
             --enable-gui=no                                          \
             --enable-tclinterp=yes                                   \
             --enable-cscope=yes                                      \
             --enable-gpm                                             \
             --enable-cscope                                          \
             --enable-fontset                                         \
             --with-x                                                 \
             --with-compiledby=koturn
$ make -j5            # 编译后可在./目录下找到可执行vim
$ sudo make install   # 如需安装到系统请执行此命令
```

## 设置clipboard为unnamedplus

在你的.vimrc中添加"set clipboard=unnamedplus"。

有一个很棒的解答：[How can I copy text to the system clipboard from Vim?](https://vi.stackexchange.com/questions/84/how-can-i-copy-text-to-the-system-clipboard-from-vim)

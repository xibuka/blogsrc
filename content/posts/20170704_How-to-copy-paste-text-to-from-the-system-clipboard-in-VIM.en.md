---
title: How to copy text to the system clipboard in VIM
date: 2017-07-04 11:44:42
tags:
- VIM
---

1. Make sure your VIM have +clipboard enabled,
1. Add "set clipboard=unnamedplus" to .vimrc

## check +clipboard is enabled

```zsh
$ vim --version | grep clipboard
+clipboard       +job             +path_extra      +user_commands
+eval            +mouse_dec       +statusline      +xterm_clipboard
```

If it shows '-clipboard', you need to compile VIM with this feature.

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
$ make -j5            # after this you can find a runable vim in ./
$ sudo make install   # run this if you want to install vim to system
```

## Set clipboard to unnamedplus

Add "set clipboard=unnamedplus" to your .vimrc.

An awesome answers is here [How can I copy text to the system clipboard from Vim?](https://vi.stackexchange.com/questions/84/how-can-i-copy-text-to-the-system-clipboard-from-vim)

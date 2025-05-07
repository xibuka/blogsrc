---
title: VIMでテキストをシステムクリップボードにコピーする方法
date: 2017-07-04 11:44:42
tags:
- VIM
---

1. VIMが+clipboard対応であることを確認する
1. .vimrcに「set clipboard=unnamedplus」を追加する

## +clipboardが有効か確認する

```zsh
$ vim --version | grep clipboard
+clipboard       +job             +path_extra      +user_commands
+eval            +mouse_dec       +statusline      +xterm_clipboard
```

'-clipboard'と表示された場合は、この機能付きでVIMをコンパイルする必要があります。

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
$ make -j5            # これで./に実行可能なvimができます
$ sudo make install   # システムにインストールしたい場合はこれを実行
```

## clipboardをunnamedplusに設定する

.vimrcに「set clipboard=unnamedplus」を追加してください。

素晴らしい回答はこちら [How can I copy text to the system clipboard from Vim?](https://vi.stackexchange.com/questions/84/how-can-i-copy-text-to-the-system-clipboard-from-vim)

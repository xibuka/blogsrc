---
title: VundleでVimのプラグインを簡単管理
date: 2016-11-21 00:37:36
tags:
- VIM
---
Vimのプラグインを管理する人気のツール、Vundleの利用メモ

本家のサイト：[https://github.com/VundleVim/Vundle.vim]

Vundleを利用するメリット
- プラグインを`.vimrc`でインストール/更新/削除できる
- 名前だけ書けば自動で探してくれる

# インストール
以下のコマンドで、ファイルをコピーするだけでインストール完了

```Bash
$ git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```


# 設定
以下の設定内容を`.vimrc`のトップに記入する。
説明のためいくつかの行がイメージになっている。
実際利用するときにコメントアウトする必要がある。

```.vimrc
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
"Plugin 'tpope/vim-fugitive'                    <- ここをコメントアウト
" plugin from http://vim-scripts.org/vim/scripts.html
"Plugin 'L9'                                    <- ここをコメントアウト
" Git plugin not hosted on GitHub
"Plugin 'git://git.wincent.com/command-t.git'   <- ここをコメントアウト
" git repos on your local machine (i.e. when working on your own plugin)
"Plugin 'file:///home/gmarik/path/to/plugin'    <- ここをコメントアウト
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
"Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}     <- ここをコメントアウト
" Install L9 and avoid a Naming conflict if you've already installed a
" different version somewhere else.
"Plugin 'ascenator/L9', {'name': 'newL9'}       <- ここをコメントアウト

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
```

# Vimのプラグインをインストールする
例として、ファイルエクスプローラーの機能を提供するプラグイン「NERDTree」を入れてみよう
`call vundle#end()`の前に、NERDTreeのgitのリンクを記入

```.vimrc
...省略
Plugin 'git@github.com:scrooloose/nerdtree.git'

" All of your Plugins must be added before the following line
call vundle#end()            " required
...省略
```

Vimを起動し、`:PluginInstall`を実行
コマンドラインからでは、`vim +PluginInstall +qall`を実行

そして画面に以下のログが出るはず

```
  " Installing plugins to /Users/shiwenhan/.vim/bundle     
. Plugin 'VundleVim/Vundle.vim'                            
. Plugin 'git@github.com:scrooloose/nerdtree.git'          
* Helptags                                                 
```

`l`を押してログを確認
```
[2016-11-21 00:56:51]                                       
[2016-11-21 00:56:51] Plugin git@github.com:scrooloose/nerdtree.git
[2016-11-21 00:56:51] $ git clone --recursive 'git@github.com:scrooloose/nerdtree.git' '/Users/shiwenhan/.vim/bundle/nerdtree'
[2016-11-21 00:56:51] > Cloning into '/Users/shiwenhan/.vim/bundle/nerdtree'...
[2016-11-21 00:56:51] >                                     
[2016-11-21 00:56:51]                                       
[2016-11-21 00:56:51] Helptags:                             
[2016-11-21 00:56:51] :helptags /Users/shiwenhan/.vim/bundle/Vundle.vim/doc
[2016-11-21 00:56:51] :helptags /Users/shiwenhan/.vim/bundle/nerdtree/doc
[2016-11-21 00:56:51] Helptags: 2 plugins processed         
```

これでプラグインのインストールが完了した。
Vimを再起動して、`:NERDTreeToggle`を実行してプラグインの確認をしましょう

![vim with NERDTree](/img/vim_NERDTree.png)

これで確認が完成！

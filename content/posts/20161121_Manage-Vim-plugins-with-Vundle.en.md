---
title: Easy Management of Vim Plugins with Vundle
date: 2016-11-21 00:37:36
tags:
- VIM
---
A memo on using Vundle, a popular tool for managing Vim plugins.

Official site: [https://github.com/VundleVim/Vundle.vim]

Benefits of using Vundle

- Install/update/remove plugins via `.vimrc`
- Just write the name and it will automatically find the plugin

## Installation

Just copy the files with the following command to complete the installation:

```Bash
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```

## Configuration

Add the following settings to the top of your `.vimrc`.
Some lines are shown as examples for explanation purposes.
You may need to comment them out when actually using them.

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
"Plugin 'tpope/vim-fugitive'                    <- Comment out here
" plugin from http://vim-scripts.org/vim/scripts.html
"Plugin 'L9'                                    <- Comment out here
" Git plugin not hosted on GitHub
"Plugin 'git://git.wincent.com/command-t.git'   <- Comment out here
" git repos on your local machine (i.e. when working on your own plugin)
"Plugin 'file:///home/gmarik/path/to/plugin'    <- Comment out here
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
"Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}     <- Comment out here
" Install L9 and avoid a Naming conflict if you've already installed a
" different version somewhere else.
"Plugin 'ascenator/L9', {'name': 'newL9'}       <- Comment out here

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

## Installing Vim Plugins

As an example, let's install the file explorer plugin "NERDTree".
Add the git link for NERDTree before `call vundle#end()`.

```.vimrc
...omitted
Plugin 'git@github.com:scrooloose/nerdtree.git'

" All of your Plugins must be added before the following line
call vundle#end()            " required
...omitted
```

Start Vim and run `:PluginInstall`.
From the command line, run `vim +PluginInstall +qall`.

You should see the following log on the screen:

```log
  " Installing plugins to /Users/shiwenhan/.vim/bundle     
. Plugin 'VundleVim/Vundle.vim'                            
. Plugin 'git@github.com:scrooloose/nerdtree.git'          
* Helptags                                                 
```

Press `l` to check the log

```log
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

This completes the plugin installation.
Restart Vim and run `:NERDTreeToggle` to check the plugin.

![vim with NERDTree](/img/vim_NERDTree.png)

That's it!

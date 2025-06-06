---
title: ログオフ後もプロセスを実行し続ける方法
date: 2017-06-29 14:31:14
tags:
- Linux
- tmux
---
tmuxはこれを実現できるオープンソースソフトウェアです。他にも多くの機能がありますが、ここではsshセッションを終了してもプロセスを動かし続ける方法を説明します。手順は以下の通りです：

1. シェルで```tmux```と入力してtmuxセッションを開始します。
1. tmuxセッション内でプロセスやスクリプトを起動します。
1. ```Ctrl+b```を押してから```d```を押すことで、tmuxセッションから離脱（デタッチ）します。

これでsshセッションを切断・ログオフしても、プロセスやスクリプトはtmuxセッション内で動き続けます。再度状態を確認したい場合は、再ログインして```tmux attach```でセッションに再接続できます。

現在動作中のセッションは```tmux list-sessions```で一覧表示できます。

tmuxはさらに多くの機能があります。詳細は```man tmux```を参照してください。

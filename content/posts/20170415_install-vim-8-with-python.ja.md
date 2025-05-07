---
title: Macでpython対応のvim8をインストールする
date: 2017-04-15 00:50:08
tags: 
- VIM
---

今日はMac Proの開発環境を設定しました。
そしてbrewを使えばpython対応のVIM8がとても簡単にインストールできることに気づきました。
（cent7よりもずっと簡単です）

brewがあれば、以下のコマンドを実行するだけです。

```bash
brew install --with-python vim
```

python3とpython2の両方に対応させたい場合は、次のコマンドを実行します。

```bash
brew install --with-python --with-python3 vim
```

追記：一部の最新OSではpython2用に下記コマンドが必要な場合があります。

```bash
brew install --with-python@2
```

古いvimのバイナリファイルを削除する必要があるかもしれません。

```bash
rm -f /usr/local/bin/vim
```

そしてvimを再リンクします。

```bash
brew link --overwrite vim

```

これで完了！快適なvimライフを

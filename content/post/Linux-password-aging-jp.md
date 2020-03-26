---
title: Linux ユーザパスワードの有効期限の管理 
date: 2017-04-27 23:15:00
tags:
- Linux
---
Linuxのユーザパスワードの有効期限(aging)の管理について説明する。

![password aging](https://raw.githubusercontent.com/xibuka/git_pics/master/passaging.png)

<!-- more -->

- last chage (-d) : パスワードが最後に変更した日数
- min days   (-m) : パスワードが変更可能の最小日数
- max days   (-M) : パスワードの変更が必要となる最大日数
- warn days  (-W) : パスワードの有効期限が近づき、変更を促す（ワーニング）の日数
- password expiration date : パスワード有効期限
- inactive days (-l) : パスワードの有効期限が切れた後に、アカウントが保持される日数
- inactive date      : アカウントが非アクティブになる期限

上記情報の変更は、chage コマンドで実現できる。

```
# chage -m 0 -M 60 -W 7 -l 30
```

また、chage コマンドに対し以下の使い方もある。

- 次回ログイン時に強制パスワードを変更させる

```
# chage -d 0 username
```

- 現在の設定一覧を表示

```
# chage -l username
```

- 指定した日付でアカウントが期限切れになる

```
# chage -E YYYY-MM-DD username
```

ユーザアカウントに関連する内容で他にも

- ロックとアンロック

```
# usermod -L username
# usermod -U username
```


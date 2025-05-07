---
title: Pythonでデスクトップ通知を送る
date: 2017-07-28 16:37:40
tags:
- Python
---
この記事では、Pythonを使ってデスクトップ通知を送る方法を紹介します。

![simpleNotification](/img/simpleNotification.png)

## 必要なもののインストール

まず、pipで`notify2`をインストールします。

```sh
$ pip install notify2
Collecting notify2
  Downloading notify2-0.3.1-py2.py3-none-any.whl
Installing collected packages: notify2
Successfully installed notify2-0.3.1
```

## コーディング

まず、notify2をインポートします。

```python
import notify2
```

次に、d-bus接続を初期化します。
D-Busは、アプリケーション同士が通信するためのメッセージバスシステムです。

```python
# d-bus接続の初期化
notify2.init("hello")
```

次に、Notificationオブジェクトを作成します。
最もシンプルな方法は以下の通りです。

```python
n = notify2.Notification(None)
```

また、通知にアイコンを追加することもできます。

```python
n = notify2.Notification(None, icon = "/home/wenshi/Pictures/me.jpg")
```

次に、通知の緊急度レベルを設定します。

```python
n.set_urgency(notify2.URGENCY_NORMAL)
```

他にも利用できるオプションは以下の通りです。

```python
notify2.URGENCY_LOW
notify2.URGENCY_NORMAL
notify2.URGENCY_CRITICAL
```

次に、通知が表示される時間を設定できます。
`set_timeout`でミリ秒単位で指定します。

```python
n.set_timeout(5000)
```

次に、通知のタイトルと本文を設定します。

```python
n.update("hello title", "hello messages")
```

通知は`show`メソッドで画面に表示されます。

```python
n.show()
```

## 実際にやってみる

```python
import notify2

# d-bus接続の初期化
notify2.init("hello")

# Notificationオブジェクトの作成
n = notify2.Notification(None, icon = "/path/to/your/image")

# 緊急度レベルの設定
n.set_urgency(notify2.URGENCY_NORMAL)

# 通知の表示時間を設定
n.set_timeout(5000)

# タイトルと本文を設定
n.update("hello title", "hello messages")

# 通知を画面に表示
n.show()
```

これで画面に通知が表示されます。
![simpleNotification](https://raw.githubusercontent.com/xibuka/git_pics/master/simpleNotification.png)

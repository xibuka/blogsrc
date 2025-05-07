---
title: GlusterFS クローンピアのプローブ失敗
date: 2017-06-15 11:43:46
tags:
- GlusterFS
---
もし gluster システムのセットアップ時間を短縮したい場合、1台のVMで必要な設定をすべて行い、それをクローンする方法があります。
しかし、別ノードからピアをプローブしようとすると問題が発生することがあります。
コマンドを実行すると、次のようなエラーメッセージが表示される場合があります：

```bash
[root@node1 ~]# gluster peer probe node2
peer probe: failed: Peer uuid (host node2) is same as local uuid
```

これは、glusterfs-server パッケージが最初にインストールされた際、ノードUUIDファイルが /var/lib/glusterd/glusterd.info に作成されるためです。
そのため、glusterfs をインストール済みのVMをクローンすると、同じUUIDを持つ glusterd.info がすべてのVMに保存されてしまいます。

解決方法は以下の通りです：

1. すべてのノードで glusterd サービスを停止する
2. /var/lib/glusterd/glusterd.info を削除する
3. すべてのノードで glusterd サービスを起動する
4. 再度 peer probe コマンドを実行する

ステップ3の後、新しいUUIDを持つ glusterd.info ファイルが作成され、この問題は解消されます。

---
title: "外部からK3sにアクセスする方法"
date: 2022-03-03T23:49:19+09:00
draft: false
---

## 外部からk3sクラスタへアクセスする

デフォルト設定でk3sクラスタを作成した場合、そのノード内からしかアクセスできません。
`/etc/rancher/k3s/k3s.yaml` のkubeconfigファイルをノード外に持ち出して他のホストでインポートしようとすると、下記のようなエラーが発生します。

```bash
❯ kubectl get node
Unable to connect to the server: x509: certificate is valid for 10.0.140.68, 10.43.0.1, 127.0.0.1, not xxx.xxx.xxx.xxx
```

ノード外からk3sクラスタにアクセスできるようにするには、クラスタ作成時に下記パラメータを指定します。

```bash
--tls-san value                            (listener) Add additional hostname or IP as a Subject Alternative Name in the TLS cert
```

このパラメータの詳細は <https://rancher.com/docs/k3s/latest/en/installation/install-options/#registration-options-for-the-k3s-server> を参照してください。

インストールコマンド例は以下の通りです。

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san <your node public ip address>" sh -
```

その後、`/etc/rancher/k3s/k3s.yaml` の内容をローカルマシンにコピーし、serverのIPアドレスを `127.0.0.1` から実際にアクセスしたいアドレスに書き換えます。

これでクラスタ情報の取得ができ、問題なくアクセスできるようになります。

```bash
❯ kubectl get node
NAME         STATUS   ROLES                  AGE   VERSION
wenhan-dev   Ready    control-plane,master   61s   v1.22.7+k3s1
```

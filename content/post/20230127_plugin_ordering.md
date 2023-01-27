---
title: "Kong GatewayのPlugin Ordering機能を試す"
date: 2023-01-27T11:42:28+09:00
draft: false
---
Kong GatewayのPoCをやっている時に、ある問題に遭いました。
PoCの要件は以下になる
- Key-authプラグインでGateway全体を保護
- Request-transformerプラグインで必要なAPI KeyをHeaderに付与し認証を突破

二つのプラグインを設定した後、API keyをrequestに追加されても認証されない

~~~
# key-auth is enabled
❯ http --header localhost:8000/demo | head -1
HTTP/1.1 401 Unauthorized

# Got 401 after creating request-transformer-adv plugin.
❯ curl -X POST http://localhost:8001/services/testsvc/plugins \
    --data "name=request-transformer-advanced"  \
    --data "config.add.headers=apikey:wenhandemo"
...
❯ http --header localhost:8000/demo | head -1
HTTP/1.1 401 Unauthorized
~~~

理由を調べたら、どうやらPluginのデフォルトの実行順番があるらしいです。

https://docs.konghq.com/gateway/latest/plugin-development/custom-logic/#plugins-execution-order

key-authのプライオリティは`1250`、request-transformer-advの`801`より高いです。よってkey-authが実行するときに、Headerに必要なAPI Keyがまだ付与されていない状態になります。

解決方法として、Kong Gateway 3.0に新しく追加された機能、plugin orderingでプラグインの実行順番を明示すればOKです。

https://docs.konghq.com/gateway/3.0.x/kong-enterprise/plugin-ordering/get-started/

よしでは実装してみよう。`request-transformer-advanced`のプラグインを設定するときに、`key-auth`の前にすると宣言します。

```
❯ curl -X POST http://localhost:8001/services/testsvc/plugins \
    --data "name=request-transformer-advanced"  \
    --data "config.add.headers=apikey:wenhandemo" \
    --data "ordering.before.access=key-auth"
...
❯ http --header localhost:8000/demo | head -1
HTTP/1.1 200 OK
```

ジャジャン♪


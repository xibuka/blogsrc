---
title: "Kong GatewayでRequestとResponseを自在にカスタマイズする方法"
date: 2024-12-23T23:49:19+09:00
draft: false
tags:
- kong
---

## 前書き

現代のアプリケーション開発では、APIは他のシステムやサービスと連携するための重要な基盤となっています。しかし、異なるシステム間でAPIの要件が合わない、データ形式が異なる、セキュリティ要件が満たされていない、といった課題は頻繁に発生しています。こうした状況において、APIゲートウェイを活用することが、リクエストとレスポンスを柔軟に変更する最も効果的な方法です。

Kong GatewayのようなAPIゲートウェイは、単なるAPI管理ツールではありません。トラフィックの流れを制御する中で、リクエストやレスポンスの内容をカスタマイズする強力な機能を提供します。たとえば、次のような項目を変更することが可能です：

- ヘッダー
  クライアントから送信されたリクエストヘッダーに認証情報やカスタム値を追加したり、レスポンスヘッダーを編集してキャッシュ制御やセキュリティに関する情報を含めたりすることができます
  
- Bodyの変換
  リクエストBodyを加工して上流のサービスが期待する形式に変更したり、レスポンスBodyの内容をフィルタリングして不要なデータを削除することが可能です
  
- ステータスコードの変更
  APIの動作に応じてステータスコードを変更し、エラー処理やリダイレクトの挙動を制御することもできます
  
- データフォーマットの変換
  古いシステムがXMLを要求するが、新しいシステムがJSONを利用している場合、APIゲートウェイでデータフォーマットを動的に変換することで互換性を確保できます
  
- 暗号化と復号化
   セキュリティ要件に応じて、リクエストやレスポンスデータを暗号化または復号化することで、通信の安全性を向上させることができます

これらの変更はすべて、APIのクライアントやバックエンドに手を加えることなく実現できる点が最大の利点です。APIゲートウェイはシステムの境界で操作を行うため、変更内容が他のシステムに影響を与えるリスクを最小限に抑えながら、柔軟なカスタマイズを可能にします。

## Kongでリクエストとレスポンスを変更する方法

この記事では、これらの変更をKong Gatewayでどのように実現するのかを具体的に解説していきます。

### Request transformer / Response transformer プラグインの紹介

Kong Gatewayが提供する[Request Transformer](https://docs.konghq.com/hub/kong-inc/request-transformer/)および[Response Transformer](https://docs.konghq.com/hub/kong-inc/response-transformer/)プラグインは、リクエストやレスポンスの内容を簡単にカスタマイズするためのツールです。このプラグインを利用すれば、リクエストやレスポンスのヘッダーやBodyを加工・変換し、システム間の調整や特定のAPI要件に応える際に役立ちます。

#### 主要な機能

Request Transformer プラグインの主な機能

- リクエストヘッダーの追加、削除、上書き
- クエリパラメータの追加、削除、上書き
- リクエストBodyの追加・削除

Response Transformer プラグインの主な機能

- レスポンスヘッダーの追加、削除、上書き
- レスポンスBodyの不要部分を削除

これらの機能を組み合わせることで、APIトラフィックを柔軟に制御することができます。

#### Plugin設定

まず、テスト用のServiceとRouteを作成します。今回はリクエストをそのままレスポンスするAPIを利用し、変更されたリクエストを確認します。

```bash
curl -i -X POST http://localhost:8001/services/ \
  --data name=echo_service \
  --data url=http://httpbin.org/anything

curl -i -X POST http://localhost:8001/services/echo_service/routes/ \
  --data name=echo_route \
  --data paths=/echo 
```

次、request transformerのプラグインを有効にし、以下のルールを設定しました。

- Authorizationヘッダーを追加
- debugクエリパラメータを削除

```bash
curl -i -X POST http://localhost:8001/services/echo_service/plugins \
    --data "name=request-transformer" \
    --data "config.add.headers=Authorization: Bearer abc123" \
    --data "config.remove.querystring=debug"
```

#### 動作確認

以下のリクエストを送信したあと、

```bash
http localhost:8000/echo\?debug=aaa\&uuid=2345
```

以下のレスポンスが返ってきました。

```bash
HTTP/1.1 200 OK
...

{
    "args": {
        "uuid": "2345"
    },
    "data": "",
    "files": {},
    "form": {},
    "headers": {
        "Accept": "*/*",
        "Accept-Encoding": "gzip, deflate",
        "Authorization": "Bearer abc123",
        "Host": "httpbin.org",
        "User-Agent": "HTTPie/2.6.0",
        "X-Amzn-Trace-Id": "Root=1-6762e0e7-74dc18834a309ed8391d33a5",
        "X-Forwarded-Host": "localhost",
        "X-Forwarded-Path": "/echo",
        "X-Forwarded-Prefix": "/echo",
        "X-Kong-Request-Id": "fc4da81ce6d1583d6a5d52531caff043"
    },
    "json": null,
    "method": "GET",
    "origin": "172.21.0.1, x.x.x.x",
    "url": "http://localhost/anything?uuid=2345"
}
```

このレスポンスの内容を確認すると、設定した内容通りでリクエストが変更されました。

- ヘッダーに`"Authorization": "Bearer abc123",`が追加された
- URLのParamに`debug=aaa`が削除された

他にも色々できることがあるので、[プラグインのページ](https://docs.konghq.com/hub/kong-inc/request-transformer/how-to/basic-example/) を参考してみてください。

### exit transformer

[exit transformer](https://docs.konghq.com/hub/kong-inc/exit-transformer/)はLua関数を使用して、Kong Gatewayのレスポンス終了メッセージを変換およびカスタマイズします。このプラグインは、メッセージ、ステータスコード、ヘッダーの変更から、Kong Gatewayレスポンスの構造全体を完全に変換することまで可能にします。

このプラグインは、4xxと5xxのレスポンスが返ってきた時に、設定されたコードが実行します。

:::note warn
現在このプラグインは、Kong内部のエラーにしか反応しなく、Upstreamからのエラーには対応していないです。
:::

#### Plugin設定
まずはテスト用のサービスとルートを登録します。

```bash
 curl -i -X POST http://localhost:8001/services \
   --data name=example.com \
   --data url='https://httpbin.konghq.com'

curl -i -X POST http://localhost:8001/services/example.com/routes \
   --data 'paths=/example'
```

プラグインが実行するスクリプトを以下のように入力し、`transform.lua`として保存しましょう。

```transform.lua
     return function(status, body, headers)
       if not body or not body.message then
         return status, body, headers
       end
       headers = { ["x-some-header"] = "some value" }
       local new_body = {
         error = true,
         status = status,
         message = body.message .. ", arr!",
       }
       return 200, new_body, headers
     end
```

このスクリプトでは、以下の項目を変更していました。

- ヘッダーに`["x-some-header"] = "some value"`を追加
- Bodyの最後に、`arr`を追加
- レスポンスのstatus codeを強制的に`200`に変更

上記の`transform.lua`を使って、`exit-transformer` plugin を有効にしましょう。

```bash
 curl -X POST http://localhost:8001/services/example.com/plugins \
   -F "name=exit-transformer"  \
   -F "config.functions=@transform.lua"
```

レスポンスがエラーになるように、key-authを追加します。

```bash
 curl -X POST http://localhost:8001/services/example.com/plugins \
   --data "name=key-auth"
```

#### 動作確認

`/example`にリクエストを送信してカスタムエラーを取得します。この場合、リクエストが認証情報（APIキー）を提供しなかったため、メッセージボディ内に401レスポンスが返されますが、clientへのレスポンスが200になっています。

```bash
http localhost:8000/example

HTTP/1.1 200 OK
...
x-some-header: some value
{
    "error": true,
    "message": "No API key found in request, arr!",
    "status": 401
}
```

## まとめ

APIゲートウェイは、異なるシステム間の調整や要件に柔軟に対応するための重要なツールです。Kong Gatewayを使用すると、リクエストやレスポンスのヘッダー、Body、ステータスコードを動的に変更し、データ形式の変換やセキュリティ強化も可能です。標準プラグインやLuaスクリプトを活用することで、システム全体の柔軟性と効率を大幅に向上させます。

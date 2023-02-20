---
title: "Kong Gatewayで実装！リクエストが失敗したらSlackWebhookで通知"
date: 2023-02-20T14:21:23+09:00
draft: false
---
## 背景

Kong Gatewayを使ってAPIにアクセスする時には、もしリクエストが失敗したら通知して欲しいですね。通常のやり方はLog系のプラグインでLogを保存してから、3rd partyの製品（ELK）でAlertを設定して通知することです。でも他の製品を使うとデプロイも面倒だし、ライセンスや設定内容も必要だし、できればKong内部で実現したいな。。という要望があると思います。
今回は、[`Exit Transformer`](https://docs.konghq.com/hub/kong-inc/exit-transformer/) プラグインを使って、リクエストがエラーだったらLuaスクリプトでSlack Webhookを叩くことをメモします。このプラグインは、Lua 関数を使用して、Kong 応答終了メッセージを変換およびカスタマイズすることができます。メッセージ、ステータスコード、ヘッダーの変更から、Kong 応答の構造の完全な変換まで、さまざまな機能があります。

## プラグインを試す

まずはページ上にある例を試してみよう。

### サービスとルートを作成

```
$ http :8001/services name=example.com host=mockbin.org
$ http -f :8001/services/example.com/routes hosts=example.com
```

### 失敗させるため key auth プラグインを実装

```
$ http :8001/services/example.com/plugins name=key-auth
```

### Luaスクリプトを作成

以下のコードでは、`x-some-header`のヘッダーを追加し、メッセージの最後に`, arr`を追加した。
この内容をtransform.luaとして保存する。

```
    -- transform.lua
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

      return status, new_body, headers
    end
```

### スクリプトを使ってプラグインをデプロイ

```
   http -f :8001/services/example.com/plugins \
     name=exit-transformer \
     config.functions=@transform.lua
```

### 動作確認
ここまで設定したらアクセスしてみましょう。ヘッダーと最後のメッセージarrがちゃんとレスポンスに追加されました。

```
❯ http :8000 Host:example.com
HTTP/1.1 401 Unauthorized
Connection: keep-alive
Content-Length: 73
Content-Type: application/json; charset=utf-8
Date: Fri, 10 Feb 2023 07:36:15 GMT
Server: kong/3.1.1.3-enterprise-edition
WWW-Authenticate: Key realm="kong"
X-Kong-Response-Latency: 2
x-some-header: some value

{
    "error": true,
    "message": "No API key found in request, arr!",
    "status": 401
}
```

## Webhookをスクリプトに実装

今回はSlackのWebhookを利用します。メッセージに内容を追加した後にWebhookをキックする実装にします。

```
...
      local httpc = require("resty.http").new()

      -- Single-shot requests use the `request_uri` interface.
      local res, err = httpc:request_uri("https://hooks.slack.com/services/xxxxxx/xxxxxx/xxxxxxxx", {
          method = "POST",
          body = '{"text": "Hello, world."}',
          headers = {
              ["Content-Type"] = "application/json",
          },
      })
      if not res then
          ngx.log(ngx.ERR, "request failed: ", err)
          return
      end

      return status, new_body, headers
...
```

リクエストを送るために、[lua-resty-http](https://github.com/ledgetech/lua-resty-http)を利用しています。一般的には`require`を利用してリクエストを出しますが、nginx イベント ループでうまく機能するとは思わない心配があります。つまり、hooks.slack.com からの応答を待機している間、nginx が他のリクエストを処理できなくなる可能性があります。

もう一つ注意すべきところは、外部のライブラリを呼び出しているため、[untrusted_lua](https://docs.konghq.com/gateway/latest/reference/configuration/#untrusted_lua)パラメータをOnにする必要があります。これをしないと以下のようなエラーが出ます。
```
2023/02/10 02:19:13 [error] 2175#0: *15812 lua entry thread aborted: runtime error: /usr/local/share/lua/5.1/kong/tools/sandbox.lua:88: require 'ssl.https' not allowed within sandbox
```

## もう一度動作確認

さてさっきのAPIにもう一度アクセスしてSlackのメッセージを確認しましょう！

```
❯ http :8000 Host:example.com
HTTP/1.1 401 Unauthorized
Connection: keep-alive
Content-Length: 73
Content-Type: application/json; charset=utf-8
Date: Mon, 13 Feb 2023 13:28:42 GMT
Server: kong/3.1.1.3-enterprise-edition
WWW-Authenticate: Key realm="kong"
X-Kong-Response-Latency: 0
x-some-header: some value

{
    "error": true,
    "message": "No API key found in request, arr!",
    "status": 401
}
```
![iShot_2023-02-13_22.29.31.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/1ec6a8fc-bbe2-550a-9fe9-190aa2c34b73.png)

きたーーーーーーーーーーーーー！



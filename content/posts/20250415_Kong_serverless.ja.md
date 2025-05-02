---
title: "KongのServerless機能を使って、リクエスト処理をもっとスマートに"
date: 2025-04-15T23:49:19+09:00
draft: false
tags:
- kong
- ServerLess
---

## Pre-function Plugin 解説と実用サンプル

Kong Gatewayは多機能なAPIゲートウェイですが、**ちょっとした処理をサーバレス関数として内蔵できる**ことをご存知でしょうか？

今回は、Luaスクリプトを使って**リクエストのBodyからUUIDを抽出し、Headerに追記＆ログ出力する**という実用的なサンプルをご紹介します。

---

## Pre-function Pluginとは？

[公式ドキュメント](https://docs.konghq.com/hub/kong-inc/pre-function/)にある通り、`pre-function`プラグインはリクエストをAPIに**送信する前にLuaで処理を記述できる**柔軟な機能です。

用途は多彩で：

- 条件分岐によるフィルタリング  
- ヘッダー／ボディのカスタマイズ  
- 軽量ログやモニタリング処理  
- メンテナンス用の簡易ブロック処理  

など、**プラグイン化するほどじゃないけど、ちょっと処理したい**というニーズにぴったりです。

---

## 実用例

今回は、リクエストボディにあるUUIDを抽出してヘッダーとログに追記する機能をServer Less機能で実現します。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/4c10fa10-6a82-4108-adde-dfba074b1dbc.png)

### 処理の流れ

1. リクエストBodyからUUIDを抽出（JSONパース）
2. UUIDがあれば `x-uuid` ヘッダーに追記
3. 抽出結果をログに出力（File Logプラグイン使用）  

---

### 前提準備：サービスとルートを作成

```bash
# サービス作成
curl -i -X POST http://localhost:8001/services \
  --data name=mock-service \
  --data url=http://httpbin.org/anything

# ルート作成
curl -i -X POST http://localhost:8001/services/mock-service/routes \
  --data 'paths[]=/uuid-test'
```

### File Log Plugin でログ出力（標準出力へ）

```bash
curl -i -X POST http://localhost:8001/services/mock-service/plugins \
  --data "name=file-log" \
  --data "config.path=/dev/stdout"
```

### Pre-functionの設定

Nginxのフェーズ毎に、カスタムコードを実行することができます。フェーズに関する詳細内容は、以下をご参考ください。
[https://nginx.org/en/docs/dev/development_guide.html#http_phases](https://nginx.org/en/docs/dev/development_guide.html#http_phases)

```bash
curl -i -X POST http://localhost:8001/services/mock-service/plugins \
  --data "name=pre-function" \
  --data "config.access[1]=
  local body, err, mimetype = kong.request.get_body()
  if body.uuid ~= nil then
      kong.service.request.add_header('uuid', body.uuid)
  end
  kong.service.request.enable_buffering()
  kong.log.set_serialize_value('request.body', kong.request.get_body())" \
  --data "config.log[1]=
  kong.log.set_serialize_value('response.body', kong.service.response.get_body())"
```

上記のコードでは、`access`フェーズと`log`フェーズに以下のコードを挿入しています。それぞれの意味をコメントで説明します。

```lua
-- リクエストからBodyを抽出
local body, err, mimetype = kong.request.get_body()

-- Bodyにあるuuidの存在を確認し、もしあったらHeaderに追加
if body.uuid ~= nil then
  kong.service.request.add_header('uuid', body.uuid)
end

-- Bodyの内容をログに追加 
kong.service.request.enable_buffering()
kong.log.set_serialize_value('request.body', kong.request.get_body())
```

```lua
-- レスポンスの内容をログに追加
kong.log.set_serialize_value('response.body', kong.service.response.get_body())
```

## リクエスト送信

`uuid`をBodyに設定してリクエストを送信します。

```json
curl -i -X POST http://localhost:8000/uuid-test \
  -H "Content-Type: application/json" \
  -d '{"uuid": "123e4567-e89b-12d3-a456-426614174000"}'
```

すると、APIに到達した時、Headerに`"Uuid": "123e4567-e89b-12d3-a456-426614174000"`が追加されています。

```json
{
  "args": {}, 
  "data": "{\"uuid\": \"123e4567-e89b-12d3-a456-426614174000\"}", 
  "files": {}, 
  "form": {}, 
  "headers": {
    "Accept": "*/*", 
    "Content-Length": "48", 
    "Content-Type": "application/json", 
    "Host": "httpbin.org", 
    "Kong-Request-Id": "acfa1af0-c53e-4129-8b89-8a16be923e35", 
    "User-Agent": "curl/8.7.1", 
    "Uuid": "123e4567-e89b-12d3-a456-426614174000", 
    "X-Amzn-Trace-Id": "Root=1-67fe09a9-7b1c7cf96bbcc28938e75a7f", 
    "X-Forwarded-Host": "localhost", 
    "X-Forwarded-Path": "/uuid-test", 
    "X-Forwarded-Prefix": "/uuid-test", 
    "X-Kong-Request-Id": "ebfdfe72b011c1100130e00f026bfb65"
  }, 
  "json": {
    "uuid": "123e4567-e89b-12d3-a456-426614174000"
  }, 
  "method": "POST", 
  "origin": "192.168.97.1, 133.201.15.64", 
  "url": "http://localhost/anything"
}
```

ログから、リクエストとレスポンスの詳細が表示されていて、Headerだけではなく、Bodyも確認できています。

```json
{
...
  "request": {
    "uri": "/uuid-test",
    "size": 187,
    "method": "POST",
    "querystring": {},
    "body": {
      "uuid": "123e4567-e89b-12d3-a456-426614174000"
    },
    "url": "http://localhost:8000/uuid-test",
    "headers": {
      "content-length": "48",
      "user-agent": "curl/8.7.1",
      "content-type": "application/json",
      "host": "localhost:8000",
      "accept": "*/*",
      "kong-request-id": "acfa1af0-c53e-4129-8b89-8a16be923e35",
      "uuid": "123e4567-e89b-12d3-a456-426614174000"
    },
    "id": "ebfdfe72b011c1100130e00f026bfb65"
  },
...
  "response": {
    "body": {
      "origin": "192.168.97.1, 133.201.15.64",
      "data": "{\"uuid\": \"123e4567-e89b-12d3-a456-426614174000\"}",
      "json": {
        "uuid": "123e4567-e89b-12d3-a456-426614174000"
      },
      "form": {},
      "method": "POST",
      "url": "http://localhost/anything",
      "files": {},
      "args": {},
      "headers": {
        "X-Forwarded-Host": "localhost",
        "Content-Type": "application/json",
        "Kong-Request-Id": "acfa1af0-c53e-4129-8b89-8a16be923e35",
        "Uuid": "123e4567-e89b-12d3-a456-426614174000",
        "X-Amzn-Trace-Id": "Root=1-67fe09a9-7b1c7cf96bbcc28938e75a7f",
        "Accept": "*/*",
        "Host": "httpbin.org",
        "X-Kong-Request-Id": "ebfdfe72b011c1100130e00f026bfb65",
        "User-Agent": "curl/8.7.1",
        "X-Forwarded-Prefix": "/uuid-test",
        "X-Forwarded-Path": "/uuid-test",
        "Content-Length": "48"
      }
    },
    "size": 1207,
    "status": 200,
    "headers": {
      "via": "1.1 kong/3.10.0.0-enterprise-edition",
      "x-kong-proxy-latency": "68",
      "content-type": "application/json",
      "x-kong-upstream-latency": "352",
      "server": "gunicorn/19.9.0",
      "content-length": "825",
      "x-kong-request-id": "ebfdfe72b011c1100130e00f026bfb65",
      "date": "Tue, 15 Apr 2025 07:24:25 GMT",
      "access-control-allow-origin": "*",
      "access-control-allow-credentials": "true",
      "connection": "close"
    }
  },
...
}
```

## まとめ

Kongのpre-functionとfile-logプラグインを組み合わせることで、外部サービスを呼ばずともAPIリクエスト内容の加工と可視化が実現できます。

Kongは単なるゲートウェイ以上に、「軽量なエッジ処理エンジン」として活用できます。Luaスクリプトをうまく使えば、REST APIの前処理をスマートに自動化できますよ！

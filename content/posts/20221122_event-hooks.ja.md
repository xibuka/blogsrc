---
title: "Kong GatewayのWebhook/event hookを試した"
date: 2022-11-22T22:57:09+09:00
draft: false 
tags: 
- Kong Gateway
- WebHook
---
Event Hooks機能を利用することで、Kong Gatewayで特定のイベントが発生したときに通知を受け取ることができます。新しい管理者やサービスを作成したり、プラグインによる制限が有効になったりすることを監視したい場合に役に立ちます。

## どのような機能?

Event Hooksには以下の４種類があります。

- webhook: 定義されたフォーマットのPOSTリクエストを送信
- webhook-custom: カスタムしたHTTPリクエストを送信
- log: Eventの内容をKong Gatewayのエラーログに記録
- lambda: 事前に用意したLua関数を起動

ここでは、`Webhook-custom`と`log`を試していきます。

## 利用可能なEventを確認

Kong Gateway は adminAPIの`/event-hooks/sources` エンドポイントを提供します。ここから利用できるソース、Eventとパラメータを確認することができます。データが大量にあるので、一部抜粋で説明します。

```json
...
    "rate-limiting-advanced": {
      "rate-limit-exceeded": {
        "fields": [
          "consumer",
          "ip",
          "service",
          "rate",
          "limit",
          "window"
        ],
        "unique": [
          "consumer",
          "ip",
          "service"
        ],
        "description": "Run an event when a rate limit has been exceeded"
      }
    },
...
```

## Event Hookの登録と検証

上記の例では、ソースが`rate-limiting-advanced`、Eventは`rate-limit-exceeded`、パラメータに`consumer`や`ip`などが利用できます。こちらの情報を使って、まずはwebhook-customのEvent Hookを作成します。

```bash
curl -k -X POST 'http://localhost:31001/event-hooks' \
    -H 'Kong-Admin-Token: kong' \
    --data "source=rate-limiting-advanced" \
    --data "event=rate-limit-exceeded" \
    --data "handler=webhook-custom" \
    --data "config.method=POST" \
    --data "config.headers.content-type=application/json" \
    --data "config.payload.text=Rate limit exceeded by username '{{ consumer.username }}' on service ' {{ service.name }}' (on server owned by $USER) " \
    --data "config.url=https://hooks.slack.com/services/TTTTTTTTT/YYYYYYYYYYY/xxxxxxxxxxxxxxxxxx"
```

これでRate LimitのEventが発生するときに、以下のようなメッセージがSlackチャンネルに送信されます。

```bash
Rate limit exceeded by username 'Joe' on service 'test' (on server owned by ubuntu)
```

`log`タイプのEvent Hooksの登録も簡単で、handlerの部分をlogに変更するだけです。

```sh
curl -k -X POST 'http://localhost:31001/event-hooks' \
    -H 'Kong-Admin-Token: kong' \
    --data "source=rate-limiting-advanced" \
    --data "event=rate-limit-exceeded" \
    --data "handler=log"
```

これによって、イベントが発生したら、以下みたいなログが出力されます。
ログレベルをDEBUGに変更する必要があります。

```log
2022/11/21 04:27:36 [debug] 2120#0: *1338 [kong] event_hooks.lua:?:452 [core]--------------------------------------------------------------------------------------+
2022/11/21 04:27:36 [debug] 2120#0: *1338 |"log callback: " { "rate-limit-exceeded", "rate-limiting-advanced", {                                                   |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |    consumer = {},                                                                                                      |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |    ip = "10.42.0.1",                                                                                                   |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |    limit = 3,                                                                                                          |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |    rate = 4,                                                                                                           |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |    service = {                                                                                                         |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |      connect_timeout = 60000,                                                                                          |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |      created_at = 1668754239,                                                                                          |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |      enabled = true,                                                                                                   |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |      host = "httpbin.org",                                                                                             |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |      id = "9d0bee90-04b9-4af3-993f-b10db881b144",                                                                      |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |      name = "demo",                                                                                                    |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |      path = "/anything",                                                                                               |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |      port = 80,                                                                                                        |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |      protocol = "http",                                                                                                |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |      read_timeout = 60000,                                                                                             |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |      retries = 5,                                                                                                      |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |      updated_at = 1668754239,                                                                                          |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |      write_timeout = 60000,                                                                                            |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |      ws_id = "d06c2d4d-3fb1-49ae-a4c8-5806328c591d"                                                                    |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |    },                                                                                                                  |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |    window = "minute"                                                                                                   |
2022/11/21 04:27:36 [debug] 2120#0: *1338 |  }, 2120 }                                                                                                             |
2022/11/21 04:27:36 [debug] 2120#0: *1338 +------------------------------------------------------------------------------------------------------------------------+
```

Event Hooksで実現できることはまだまだたくさんありますが、今日はここまでにしましょう。興味を持つ人はぜひチャレンジしてみてください。

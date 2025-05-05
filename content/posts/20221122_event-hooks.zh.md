---
title: "Kong Gateway 的 Webhook/Event Hook 试用"
date: 2022-11-22T22:57:09+09:00
draft: false 
tags: 
- Kong Gateway
- WebHook
---
通过 Event Hooks 功能，可以在 Kong Gateway 中发生特定事件时收到通知。如果你想监控新管理员或服务的创建，或插件限流等事件，这会非常有用。

## 这是什么功能？

Event Hooks 有四种类型：

- webhook：发送定义格式的 POST 请求
- webhook-custom：发送自定义 HTTP 请求
- log：将事件内容记录到 Kong Gateway 的错误日志中
- lambda：触发预定义的 Lua 函数

本文将演示 `webhook-custom` 和 `log` 的用法。

## 查看可用事件

Kong Gateway 的 admin API 提供了 `/event-hooks/sources` 端点，可以查看可用的 source、event 及参数。数据较多，这里只摘录部分：

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

## 注册和验证 Event Hook

如上例，source 为 `rate-limiting-advanced`，event 为 `rate-limit-exceeded`，可用参数有 `consumer`、`ip` 等。基于这些信息，先创建一个 webhook-custom 类型的 Event Hook：

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

这样，当发生 Rate Limit 事件时，会向 Slack 频道发送如下消息：

```bash
Rate limit exceeded by username 'Joe' on service 'test' (on server owned by ubuntu)
```

注册 `log` 类型的 Event Hook 也很简单，只需将 handler 改为 log：

```sh
curl -k -X POST 'http://localhost:31001/event-hooks' \
    -H 'Kong-Admin-Token: kong' \
    --data "source=rate-limiting-advanced" \
    --data "event=rate-limit-exceeded" \
    --data "handler=log"
```

这样事件发生时会输出如下日志。需要将日志级别设置为 DEBUG。

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

Event Hooks 能实现的功能还有很多，今天就先到这里。如果你感兴趣，不妨试试看！

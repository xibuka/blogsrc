---
title: "Trying Out Kong Gateway's Webhook/Event Hook"
date: 2022-11-22T22:57:09+09:00
draft: false 
tags: 
- Kong Gateway
- WebHook
---
By using the Event Hooks feature, you can receive notifications when specific events occur in Kong Gateway. This is useful if you want to monitor things like the creation of new administrators or services, or when plugin-based restrictions are triggered.

## What is this feature?

Event Hooks come in four types:

- webhook: Sends a POST request in a defined format
- webhook-custom: Sends a customized HTTP request
- log: Records the event content in Kong Gateway's error log
- lambda: Triggers a pre-defined Lua function

Here, we'll try out `webhook-custom` and `log`.

## Checking Available Events

Kong Gateway provides the `/event-hooks/sources` endpoint in the admin API. Here, you can check available sources, events, and parameters. The data is extensive, so here's a partial example:

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

## Registering and Testing Event Hooks

In the above example, the source is `rate-limiting-advanced`, the event is `rate-limit-exceeded`, and parameters like `consumer` and `ip` are available. Using this information, let's first create a webhook-custom Event Hook.

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

Now, when a Rate Limit event occurs, a message like the following will be sent to a Slack channel:

```bash
Rate limit exceeded by username 'Joe' on service 'test' (on server owned by ubuntu)
```

Registering a `log` type Event Hook is also easy—just change the handler to `log`.

```sh
curl -k -X POST 'http://localhost:31001/event-hooks' \
    -H 'Kong-Admin-Token: kong' \
    --data "source=rate-limiting-advanced" \
    --data "event=rate-limit-exceeded" \
    --data "handler=log"
```

With this, when the event occurs, a log like the following will be output. You need to set the log level to DEBUG.

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

There are many more things you can do with Event Hooks, but let's stop here for today. If you're interested, give it a try!

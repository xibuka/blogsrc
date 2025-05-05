---
title: "试用 Kong Gateway 的 Plugin Ordering 功能"
date: 2023-01-27T11:42:28+09:00
draft: false
tags: 
- Kong Gateway
- plugin
---
在做 Kong Gateway 的 PoC 时遇到了一个问题。
PoC 的需求如下：

- 用 Key-auth 插件保护整个 Gateway
- 用 Request-transformer 插件将所需的 API Key 添加到 Header 以通过认证

配置好两个插件后，即使在请求中添加了 API key，认证依然失败。

``` bash
# key-auth is enabled
❯ http --header localhost:8000/demo | head -1
HTTP/1.1 401 Unauthorized

# 创建 request-transformer-adv 插件后依然 401。
❯ curl -X POST http://localhost:8001/services/testsvc/plugins \
    --data "name=request-transformer-advanced"  \
    --data "config.add.headers=apikey:wenhandemo"
...
❯ http --header localhost:8000/demo | head -1
HTTP/1.1 401 Unauthorized
```

查了一下原因，发现插件有默认的执行顺序。

[https://docs.konghq.com/gateway/latest/plugin-development/custom-logic/#plugins-execution-order](https://docs.konghq.com/gateway/latest/plugin-development/custom-logic/#plugins-execution-order)

key-auth 的优先级是 `1250`，比 request-transformer-adv 的 `801` 高。因此 key-auth 执行时，Header 里还没有加上所需的 API Key。

解决方法是用 Kong Gateway 3.0 新增的 plugin ordering 功能，显式指定插件的执行顺序。

[https://docs.konghq.com/gateway/3.0.x/kong-enterprise/plugin-ordering/get-started/](https://docs.konghq.com/gateway/3.0.x/kong-enterprise/plugin-ordering/get-started/)

下面来实现一下。在配置 `request-transformer-advanced` 插件时，声明它要在 `key-auth` 之前执行。

```bash
❯ curl -X POST http://localhost:8001/services/testsvc/plugins \
    --data "name=request-transformer-advanced"  \
    --data "config.add.headers=apikey:wenhandemo" \
    --data "ordering.before.access=key-auth"
...
❯ http --header localhost:8000/demo | head -1
HTTP/1.1 200 OK
```

搞定！

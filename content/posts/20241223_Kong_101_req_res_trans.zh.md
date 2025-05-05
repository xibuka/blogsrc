---
title: "如何用 Kong Gateway 灵活定制请求与响应"
date: 2024-12-23T23:49:19+09:00
draft: false
tags:
- kong
---

## 前言

在现代应用开发中，API 是系统与服务集成的关键基础。然而，不同系统间常常会遇到 API 要求不一致、数据格式不同、安全要求不满足等问题。此时，利用 API 网关灵活地修改请求和响应，是最有效的解决方式。

像 Kong Gateway 这样的 API 网关不仅仅是 API 管理工具。它在流量控制过程中，提供了强大的请求与响应内容定制能力。例如，可以实现如下操作：

- Header 头部
  可以为客户端请求头添加认证信息或自定义值，也可以编辑响应头，加入缓存控制或安全相关信息。
  
- Body 转换
  可以加工请求体，使其符合上游服务的格式要求，或过滤响应体内容，去除不需要的数据。
  
- 状态码变更
  可根据 API 行为修改状态码，灵活控制错误处理或重定向。
  
- 数据格式转换
  如果老系统要求 XML，新系统用 JSON，可以在 API 网关动态转换数据格式，实现兼容。
  
- 加密与解密
   根据安全要求，对请求和响应数据进行加密或解密，提升通信安全性。

这些变更都无需改动 API 客户端或后端。API 网关在系统边界操作，既能灵活定制，又能最大限度降低对其他系统的影响。

## 如何用 Kong 修改请求与响应

本文将详细介绍如何用 Kong Gateway 实现上述变更。

### Request transformer / Response transformer 插件简介

Kong Gateway 提供的 [Request Transformer](https://docs.konghq.com/hub/kong-inc/request-transformer/) 和 [Response Transformer](https://docs.konghq.com/hub/kong-inc/response-transformer/) 插件，是便捷定制请求与响应内容的利器。通过这些插件，可以灵活处理请求/响应头和 Body，满足系统集成和特定 API 需求。

#### 主要功能

Request Transformer 插件主要功能：

- 添加、删除、覆盖请求头
- 添加、删除、覆盖查询参数
- 添加或删除请求体字段

Response Transformer 插件主要功能：

- 添加、删除、覆盖响应头
- 删除响应体中不需要的部分

结合这些功能，可以灵活控制 API 流量。

#### 插件配置

首先，创建测试 Service 和 Route。本例用回显请求的 API，方便观察请求被修改的效果。

```bash
curl -i -X POST http://localhost:8001/services/ \
  --data name=echo_service \
  --data url=http://httpbin.org/anything

curl -i -X POST http://localhost:8001/services/echo_service/routes/ \
  --data name=echo_route \
  --data paths=/echo 
```

然后启用 request transformer 插件，并设置如下规则：

- 添加 Authorization 头
- 删除 debug 查询参数

```bash
curl -i -X POST http://localhost:8001/services/echo_service/plugins \
    --data "name=request-transformer" \
    --data "config.add.headers=Authorization: Bearer abc123" \
    --data "config.remove.querystring=debug"
```

#### 效果验证

发送如下请求：

```bash
http localhost:8000/echo\?debug=aaa\&uuid=2345
```

会收到如下响应：

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

可以看到，请求被按预期修改：

- Header 中新增了 `"Authorization": "Bearer abc123",`
- URL 参数 `debug=aaa` 被删除

更多玩法可参考 [插件官方文档](https://docs.konghq.com/hub/kong-inc/request-transformer/how-to/basic-example/)。

### exit transformer

[exit transformer](https://docs.konghq.com/hub/kong-inc/exit-transformer/) 插件允许用 Lua 函数自定义 Kong Gateway 的响应终止消息。它可以修改消息、状态码、头部，甚至完全重构响应结构。

该插件会在返回 4xx 或 5xx 响应时执行配置的代码。

:::note warn
目前该插件只对 Kong 内部错误生效，不处理上游服务的错误。
:::

#### exit transformer 插件配置

首先注册测试服务和路由。

```bash
 curl -i -X POST http://localhost:8001/services \
   --data name=example.com \
   --data url='https://httpbin.konghq.com'

curl -i -X POST http://localhost:8001/services/example.com/routes \
   --data 'paths=/example'
```

将如下脚本保存为 `transform.lua`，插件会执行它：

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

该脚本做了如下变更：

- Header 中新增 `["x-some-header"] = "some value"`
- Body 结尾追加 `arr`
- 响应状态码强制为 `200`

用上述 `transform.lua` 启用 exit-transformer 插件：

```bash
 curl -X POST http://localhost:8001/services/example.com/plugins \
   -F "name=exit-transformer"  \
   -F "config.functions=@transform.lua"
```

添加 key-auth 插件以触发错误响应：

```bash
 curl -X POST http://localhost:8001/services/example.com/plugins \
   --data "name=key-auth"
```

#### exit transformer 效果验证

请求 `/example` 以获取自定义错误。此时因未提供认证（API key），消息体返回 401，但客户端实际收到 200 响应。

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

## 总结

API 网关是系统集成和需求适配的关键工具。用 Kong Gateway，可以动态修改请求/响应头、Body、状态码，支持数据格式转换和安全增强。结合标准插件和 Lua 脚本，能极大提升系统的灵活性和效率。

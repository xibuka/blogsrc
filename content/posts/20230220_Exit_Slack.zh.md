---
title: "用 Kong Gateway 实现！请求失败时通过 Slack Webhook 通知"
date: 2023-02-20T14:21:23+09:00
draft: false
tags: 
- Kong Gateway
- WebHook
- plugin
---
## 背景

使用 Kong Gateway 访问 API 时，如果请求失败，通常希望能收到通知。常规做法是用日志类插件保存日志，再用第三方产品（如 ELK）设置告警和通知。但引入其他产品部署麻烦，还涉及授权和配置，最好能直接在 Kong 内部实现。本文记录如何用 [`Exit Transformer`](https://docs.konghq.com/hub/kong-inc/exit-transformer/) 插件，在请求出错时通过 Lua 脚本调用 Slack Webhook 实现通知。该插件允许用 Lua 函数自定义和转换 Kong 的响应消息，包括修改消息、状态码、Header，甚至完全自定义响应结构。

## 插件试用

先试试官方文档的例子。

### 创建 Service 和 Route

```bash
http :8001/services name=example.com host=mockbin.org
http -f :8001/services/example.com/routes hosts=example.com
```

### 添加 key-auth 插件制造失败

```bash
http :8001/services/example.com/plugins name=key-auth
```

### 编写 Lua 脚本

下面的代码会添加 `x-some-header` 头，并在 message 末尾加上 `, arr`。保存为 `transform.lua`。

```lua
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

### 部署插件并加载脚本

```bash
http -f :8001/services/example.com/plugins \
     name=exit-transformer \
     config.functions=@transform.lua
```

### 验证效果

配置好后访问服务，响应中会多出 header 和 arr 结尾的 message。

```bash
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

## 在脚本中实现 Webhook

这次用 Slack 的 Webhook。消息内容处理后，脚本会调用 webhook。

```lua
...
      local httpc = require("resty.http").new()

      -- 单次请求用 request_uri 接口。
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

这里用到了 [lua-resty-http](https://github.com/ledgetech/lua-resty-http)。一般用 `require` 发请求，但要注意和 nginx 事件循环的兼容性——等待 hooks.slack.com 响应时，nginx 可能无法处理其他请求。

另外，由于调用了外部库，需要将 [untrusted_lua](https://docs.konghq.com/gateway/latest/reference/configuration/#untrusted_lua) 参数设为 On，否则会报如下错误：

```log
2023/02/10 02:19:13 [error] 2175#0: *15812 lua entry thread aborted: runtime error: /usr/local/share/lua/5.1/kong/tools/sandbox.lua:88: require 'ssl.https' not allowed within sandbox
```

## 再次验证

再次访问 API，检查 Slack 是否收到消息！

```bash
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

成功收到通知！

---
title: "用 Kong Serverless 功能让请求处理更智能"
date: 2025-04-15T23:49:19+09:00
draft: false
tags:
- kong
- ServerLess
---

## Pre-function 插件解读与实用示例

Kong Gateway 是功能强大的 API 网关，但你知道它可以直接内嵌**轻量级 serverless 函数**吗？

本文将用 Lua 脚本演示一个实用场景：**从请求 Body 中提取 UUID，写入 Header 并输出到日志**。

---

## 什么是 Pre-function 插件？

如[官方文档](https://docs.konghq.com/hub/kong-inc/pre-function/)所述，`pre-function` 插件允许你在**API 请求发送前用 Lua 处理请求**，非常灵活。

常见用途包括：

- 条件过滤
- Header/Body 定制
- 轻量日志或监控
- 简单的维护拦截

适合"无需专门开发插件、只想做点小处理"的场景。

---

## 实用案例

本例用 serverless 功能实现：从请求体提取 UUID，写入 Header 并记录日志。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/4c10fa10-6a82-4108-adde-dfba074b1dbc.png)

### 处理流程

1. 从请求体提取 UUID（JSON 解析）
2. 若有 UUID，则写入 `x-uuid` 头
3. 提取结果写入日志（用 File Log 插件）

---

### 前置准备：创建 Service 和 Route

```bash
# 创建服务
curl -i -X POST http://localhost:8001/services \
  --data name=mock-service \
  --data url=http://httpbin.org/anything

# 创建路由
curl -i -X POST http://localhost:8001/services/mock-service/routes \
  --data 'paths[]=/uuid-test'
```

### 用 File Log 插件输出日志（到标准输出）

```bash
curl -i -X POST http://localhost:8001/services/mock-service/plugins \
  --data "name=file-log" \
  --data "config.path=/dev/stdout"
```

### Pre-function 配置

你可以在 Nginx 的各个阶段执行自定义代码。关于阶段详情见：
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

上述代码分别在 `access` 和 `log` 阶段插入如下 Lua 代码，注释如下：

```lua
-- 从请求中提取 Body
local body, err, mimetype = kong.request.get_body()

-- 如果 Body 有 uuid，则加到 Header
if body.uuid ~= nil then
  kong.service.request.add_header('uuid', body.uuid)
end

-- 把 Body 内容写入日志
kong.service.request.enable_buffering()
kong.log.set_serialize_value('request.body', kong.request.get_body())
```

```lua
-- 把响应内容写入日志
kong.log.set_serialize_value('response.body', kong.service.response.get_body())
```

## 发送请求

Body 带 uuid 字段发送请求：

```json
curl -i -X POST http://localhost:8000/uuid-test \
  -H "Content-Type: application/json" \
  -d '{"uuid": "123e4567-e89b-12d3-a456-426614174000"}'
```

到达 API 时，Header 会包含 `"Uuid": "123e4567-e89b-12d3-a456-426614174000"`。

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

日志中可看到请求和响应的详细内容，包括 Header 和 Body。

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

## 总结

结合 Kong 的 pre-function 和 file-log 插件，无需外部服务即可实现 API 请求内容的加工与可视化。

Kong 不只是网关，更是"轻量边缘处理引擎"。善用 Lua 脚本，可让 REST API 前置处理自动化、智能化！

---
title: "Kong API Gateway 入门 - Kong gateway 入门 - 流量限制的实现方法"
date: 2024-12-03T23:49:19+09:00
draft: false
tags:
- kong
- RateLimiting
---

## 流量限制（Rate Limiting）的重要性

在当今的 API 经济中，流量限制（Rate Limiting）在系统稳定性、安全性和成本效率方面起着至关重要的作用。下面详细说明其重要性。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/fa88a4e5-e1dc-e2b9-c1fc-a93b16ab9b6d.png)

### 服务器负载管理

API 可能会收到不可预测数量的请求。例如，突然爆火的应用或意外的流量激增（即"流量高峰"）可能导致服务器过载。通过设置流量限制，可以控制最大请求量，确保服务器维持良好性能。

### 公平性保障

流量限制是保障所有用户公平访问 API 的重要手段。它防止某些用户或应用独占资源，保护其他用户的体验。

### 提升安全性

流量限制对于防御恶意请求、DoS（拒绝服务）攻击和机器人滥用非常有效。通过检测并限制异常请求模式，可以保护 API 及整个系统。

### 成本管理

许多云服务商和基础设施服务会按请求数或数据流量计费。若允许无限制请求，可能导致意外的高额费用。通过设置流量限制，可以更好地预测成本，避免不必要的支出。

## Kong 的流量限制基本机制

Kong Gateway 是一个开源 API 网关，便于管理和保护 API。企业和开发者常用它提升 API 的安全性、性能和可靠性。Kong Gateway 的流量限制功能用于控制 API 端点的流量，通过插件形式提供，配置简单灵活。

Kong 的流量限制插件工作原理如下：

1. **请求计数**
   插件会统计请求数，在指定时间窗口（秒、分、时、天等）内超出设定阈值时进行限制。
2. **超限时的处理**
   超出阈值的请求会被拒绝，返回 HTTP 状态码（通常为 429 Too Many Requests），也可自定义错误信息。
3. **存储方式**
   计数信息可存储在本地内存或 Redis 等外部存储中，从而保证分布式环境下的一致性。
4. **灵活的应用范围**
   - 按 Service：为特定 API 设置限制
   - 按 Consumer：为不同用户或应用设置不同限制
   - 按 Route：仅为特定 API 端点设置限制

## 基本配置：Kong 流量限制插件

Kong 提供两种流量限制插件，均可按时间单位限制请求数。例如，可轻松设置每分钟最多 3 次请求。

- [OSS] `https://docs.konghq.com/hub/kong-inc/rate-limiting/`
- [Enterprise] `https://docs.konghq.com/hub/kong-inc/rate-limiting-advanced/`

### 插件配置

本文以 OSS 版为例。首先创建测试用 Service 和 Route。

```bash
curl -i -X POST http://localhost:8001/services/ \
  --data name=uuid_service \
  --data url=http://httpbin.org/uuid

curl -i -X POST http://localhost:8001/services/uuid_service/routes/ \
  --data name=uuid_route \
  --data paths=/uuid 
```

未设置限制时，可以无限制生成 UUID。

```bash
curl http://localhost:8000/uuid
{
  "uuid": "84677e6f-911c-457b-a74f-d825e84248cb"
}
```

接下来，为 Service 创建 Rate Limiting 插件。

```bash
curl -X POST http://localhost:8001/services/uuid_service/plugins \
    --data "name=rate-limiting" \
    --data "config.minute=5"
```

该命令会为 `uuid_service` Service 注册如下配置：

- 插件：Rate Limiting
- 限制：每分钟最多访问 5 次

如需应用于 Route 或 Consumer，只需将 `services/uuid_service` 部分相应修改即可。

### 动作验证

前 5 次访问均正常：

```bash
curl http://localhost:8000/uuid
{
  "uuid": "6d1c137e-3707-4d50-a64c-89d7ac083ed0"
}
curl http://localhost:8000/uuid
{
  "uuid": "d3184480-124d-4ec4-a03a-c3f497260e2c"
}
curl http://localhost:8000/uuid
{
  "uuid": "3fb50124-535c-4851-b63c-4646054b88b4"
}
curl http://localhost:8000/uuid
{
  "uuid": "59db16f2-6aeb-4301-b88e-7fe28c3d0558"
}
curl http://localhost:8000/uuid
{
  "uuid": "56f4472b-5e68-4c9a-afcb-28a2899cc95b"
}
```

第 6 次起会返回错误：

```bash
curl http://localhost:8000/uuid
{
  "message":"API rate limit exceeded",
  "request_id":"090e45286c55141b7fc47640d3df482d"
}
```

## 进阶配置

### 错误信息与响应码

如需自定义错误信息和错误码，可如下设置：

```bash
curl -X POST http://localhost:8001/services/uuid_service/plugins \
    --data "name=rate-limiting" \
    --data "config.minute=5" \
    --data "config.error_code=429" \
    --data "config.error_message=请稍等片刻"
```

超过 5 次访问时，会返回自定义响应：

```bash
curl -S http://localhost:8000/uuid
{
  "message":"请稍等片刻",
  "request_id":"fd0f1d3851d1487748035047959b4242"
}%                                                                                                                                     
curl -I http://localhost:8000/uuid
HTTP/1.1 429 Too Many Requests
Date: Tue, 03 Dec 2024 08:21:25 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
X-RateLimit-Limit-Minute: 5
X-RateLimit-Remaining-Minute: 0
RateLimit-Reset: 35
Retry-After: 35
RateLimit-Remaining: 0
RateLimit-Limit: 5
Content-Length: 84
X-Kong-Response-Latency: 1
Server: kong/3.8.0.0-enterprise-edition
X-Kong-Request-Id: 2987f03c7d71364a57f6904500d3a915
```

### 请求计数器与 Redis 的使用

Kong 的 Rate Limiting 插件支持将请求计数器存储在数据库、内存或 Redis 中。不同存储方式各有特点，应根据实际环境选择。

#### 存储在数据库

如将计数器存储在数据库，所有 Kong 节点需连接同一数据库，实现节点间计数共享。但在 dbless 或 hybrid 模式下无法使用。

#### 存储在内存

适用于单节点高性能场景，分布式环境下有限制。

#### 存储在 Redis

使用 Redis 可实现集群范围内的计数共享。所有 Kong 节点指向同一 Redis 实例，保证全局准确计数。Redis 性能高，适合大流量场景。但需额外部署 Redis，并考虑 Redis 故障时的应对。

#### Redis 配置示例

用如下文件通过 docker compose 部署 Redis，`"--requirepass kong"` 设置了 Redis 密码。

```yaml
version: "3.9"

services:
  redis:
    image: redis:latest
    container_name: redis-no-auth
    ports:
      - "6379:6379"
    command: ["redis-server", "--requirepass", "kong"]

```

用如下命令配置 Rate Limiting：

```bash
curl -X POST http://localhost:8001/services/uuid_service/plugins \
    --data "name=rate-limiting" \
    --data "config.minute=5" \
    --data "config.policy=redis" \
    --data "config.redis.host=18.178.66.113" \
    --data "config.redis.port=6379" \
    --data "config.redis.username=default" \
    --data "config.redis.password=kong" 
```

- `config.policy=redis`：计数器存储在 Redis
- `config.host`：Redis 主机名
- `config.port`：Redis 端口
- `config.username`：Redis 用户名（默认 `default`）
- `config.password`：Redis 密码（本例为 `kong`）

多次请求后，可用如下命令在 Redis 内查看计数器：

```bash
# 进入 Redis 容器
> docker exec -it 51 sh

# 用密码登录
> redis-cli -a kong

# 发送一次请求后列出所有 key
127.0.0.1:6379> keys *
1) "ratelimit:00000000-0000-0000-0000-000000000000:628a172c-a98f-4355-a09b-f78f8e7f2562:172.21.0.1:1733231580000:minute"

# 查看该 key 的值，应为 1
127.0.0.1:6379> get ratelimit:00000000-0000-0000-0000-000000000000:628a172c-a98f-4355-a09b-f78f8e7f2562:172.21.0.1:1733231580000:minute
"1"
```

### 按时间动态调整限制

结合 Pre-function 和 Rate Limiting，可以根据时间动态调整流量限制。实际操作中，为同一 Service 创建两个 Route，分别设置不同 Header 条件。通过 Pre-function 根据时间设置不同 Header，实现该功能。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/bc2c03f6-2bd3-24bd-9cc9-5d56c3967ef4.png)

首先创建测试用 Service。

```bash
curl -i -X POST http://localhost:8001/services \
  --data "name=httpbin" \
  --data "url=https://httpbin.konghq.com/anything"
```

然后创建两个 Route，路径相同但 Header 条件不同。

```bash
curl -i -X POST http://localhost:8001/services/httpbin/routes \
   --data "name=peak" \
   --data "paths=/httpbin" \
   --data "headers.X-Peak=true"

curl -i -X POST http://localhost:8001/services/httpbin/routes \
   --data "name=off-peak" \
   --data "paths=/httpbin" \
   --data "headers.X-Off-Peak=true"
```

接着为每个 Route 配置 Rate Limiting 插件。

```bash
curl -i -X POST http://localhost:8001/routes/peak/plugins/  \
   --data "name=rate-limiting" \
   --data "config.minute=10" 

curl -i -X POST http://localhost:8001/routes/off-peak/plugins/  \
   --data "name=rate-limiting" \
   --data "config.minute=60" 
```

最后用 Pre-function 根据时间设置 Header，使流量路由到正确的 Route。

将以下内容保存为 `ratelimit.lua`。该函数根据操作系统时间判断当前时段，并据此设置 Header（08:00-17:00 为 X-Peak，否则为 X-Off-Peak）。

```ratelimit.lua
local hour = os.date("*t").hour 
if hour >= 8 and hour <= 17 
then
    kong.service.request.set_header("X-Peak","true") 
else
    kong.service.request.set_header("X-Off-Peak","true") 
end
```

设置为 rewrite 阶段执行：

```bash
curl -i -X POST http://localhost:8001/plugins \
    --form "name=pre-function" \
    --form "config.rewrite[1]=@ratelimit.lua"
```

这样即可实现工作时间（08:00-17:00）每分钟 10 次，非工作时间每分钟 60 次的流量限制。

## OSS 与 Enterprise 的区别

[Rate Limiting Advanced 文档](https://docs.konghq.com/hub/kong-inc/rate-limiting-advanced/) 介绍了与 OSS 插件的区别：

- 多重限制与多窗口支持
  - 例如设置每天 1000 次限制，但若全部集中在最后一分钟发送，API 仍会被压垮。可同时设置每天 1000 次 + 每分钟 60 次等多重限制，解决该问题。
- 支持 Redis Sentinel、Redis 集群和 Redis SSL
- 更高吞吐量和准确性
- 更多流量限制算法
- 支持 Consumer groups

## 总结

本文介绍了 Kong Gateway 流量限制的重要性、基本机制及配置方法。流量限制是保障 API 稳定运行、安全和成本管理的关键技术。得益于 Kong 灵活的插件设计，这一功能可以高效便捷地实现。

Kong OSS 版已能满足大多数需求，如有更复杂场景可考虑 Enterprise 版，企业版提供更多高级功能和更高性能。

希望本文能为你用 Kong 管理 API 提供参考。欢迎关注后续更多 API 与微服务运维技术博客！

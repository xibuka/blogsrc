---
title: "Kong Gateway 管理 GraphQL API 的接入与治理"
date: 2025-03-25T23:49:19+09:00
draft: false
tags:
- kong
- GraphQL
---

## GraphQL 简介回顾

GraphQL 是 Facebook 开发的一种 API 查询语言，相比传统 REST API，能更灵活地获取数据。

### GraphQL 的特点

- **单一端点**：REST API 需要多个端点，GraphQL 只需一个端点（如 `/graphql`），可发送不同查询。
- **只获取所需数据**：客户端可指定所需字段，避免无用数据传输。
- **类型系统**：API 的 schema 以类型定义，数据结构清晰。

例如，向 `https://countries.trevorblades.com/` 这个 GraphQL API 发送如下查询，可获取日本的国家信息：

```graphql
{
  country(code: "JP") {
    name
    capital
    currency
  }
}
```

用 `curl` 执行该查询：

```sh
curl -X POST https://countries.trevorblades.com/ \
  -H "Content-Type: application/json" \
  -d '{"query": "{ country(code: \"JP\") { name capital currency } }"}'
```

响应：

```json
{
  "data": {
    "country": {
      "name": "Japan",
      "capital": "Tokyo",
      "currency": "JPY"
    }
  }
}
```

GraphQL 的强大之处在于可灵活调整查询内容。例如去掉 `capital` 字段：

```sh
curl -X POST https://countries.trevorblades.com/ \
  -H "Content-Type: application/json" \
  -d '{"query": "{ country(code: \"JP\") { name currency } }"}'
```

响应中就没有 `capital` 字段：

```json
{
  "data": {
    "country": {
      "name": "Japan",
      "currency": "JPY"
    }
  }
}
```

你可以随时动态调整所需数据类型。

### GraphQL 的劣势

- **复杂性**：客户端需自行设计查询，学习曲线高于 REST。
- **缓存难度大**：REST 可基于 URL 缓存，GraphQL 主要用 POST，缓存策略更复杂。
- **负载问题**：客户端可发复杂查询，服务器压力可能增大。

## Kong 概述

Kong 是开源 API 网关，负责 API 管理、认证、路由、负载均衡等。

### Kong 的作用

- **API 管理**：API 发布、认证、限流、监控
- **插件扩展**：支持认证、缓存、限流、转换等插件
- **负载均衡与可扩展性**：可将请求分发到多个后端服务

Kong 不仅能管理 RESTful API，也能管理 GraphQL API。GraphQL 灵活高效，Kong 是实际运维 GraphQL API 的利器。

### Kong 可用的 GraphQL 相关插件

- DeGraphQL：将 GraphQL API 转换为 RESTful API 使用的插件
- GraphQL Caching：缓存 GraphQL 响应，降低重复请求负载
- GraphQL Rate Limiting：限制 GraphQL API 请求数的插件

## DeGraphQL 插件介绍

**DeGraphQL** 插件让你在 Kong 中像操作 RESTful API 一样操作 GraphQL。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/f028b415-adbe-46f8-bd0d-09f198da8de5.png)

### 主要功能

- 将对 GraphQL API 的请求转换为 REST 格式
- 客户端无需编写 GraphQL 查询
- 可用现有 REST API 客户端和工具直接访问

这样即使不懂 GraphQL 的开发者也能轻松获取数据。

---

### Demo：用 Kong 像 REST 一样访问 GraphQL

#### 创建 Service 和 Route

首先创建指向 GraphQL 端点的 Service，并定义对应 Route。

```sh
# 创建 Service
curl -i -X POST http://localhost:8001/services \
  --data "name=countries-graphql" \
  --data "url=https://countries.trevorblades.com/"

# 创建 Route
curl -i -X POST http://localhost:8001/routes \
  --data "service.name=countries-graphql" \
  --data "paths[]=/dql"
```

#### 启用 DeGraphQL 插件

然后为 Service 启用 DeGraphQL 插件。注意该插件**只能在 Service 层创建**。

```sh
curl -X POST http://localhost:8001/services/countries-graphql/plugins \
    --data name="degraphql"
```

#### DeGraphQL 路由配置

最后创建 DeGraphQL 路由，设置 GraphQL 查询内容。

```sh
curl -X POST http://localhost:8001/services/countries-graphql/degraphql/routes \
  --data uri='/:country' \
  --data query='query ($country:ID!) {
    country(code: $country) {
      name
      native
      capital
      emoji
      currency
      languages {
        code
        name
      }
    }
  }'
```

### 通过 Kong 像 REST 一样访问

配置完成后，可像 REST API 一样通过 Kong 访问：

```sh
curl -X GET http://localhost:8000/dql/JP
```

会返回如下响应：

```json
{
  "name": "Japan",
  "native": "日本",
  "capital": "Tokyo",
  "emoji": "🇯🇵",
  "currency": "JPY",
  "languages": [
    {
      "code": "ja",
      "name": "Japanese"
    }
  ]
}
}
```

本 Demo 展示了如何用 Kong 的 DeGraphQL 插件将 GraphQL API 当作 REST API 使用。

### 优势

- 不懂 GraphQL 的开发者也能像用 REST 一样访问
- 现有 REST 客户端可直接复用
- 利用 Kong 作为 API 网关实现灵活路由

## GraphQL Proxy Caching Advanced 插件介绍

GraphQL Proxy Caching Advanced 是 Kong 的 GraphQL API 高级缓存插件。它缓存 GraphQL 响应，避免重复请求重复计算，提升性能。

### 主要功能

- **请求缓存**：对相同查询应用缓存，减轻后端压力
- **缓存过期设置**：可设置 TTL（存活时间），合理保留缓存
- **缓存绕过**：可将特定请求排除在缓存之外

### GraphQL Proxy Caching Advanced Demo

#### 启用插件

首先为目标 Service 启用 GraphQL Proxy Caching Advanced。

```sh
curl -X POST http://localhost:8001/services/countries-graphql/plugins \
  --data name="graphql-proxy-cache-advanced" \
  --data config.strategy="memory" \
  --data config.cache_ttl=300
```

此配置将缓存策略设为内存，TTL 为 300 秒（5 分钟）。也可用 Redis。

#### 验证缓存效果

第一次请求（无缓存）：

```sh
curl -vvv -X GET http://localhost:8000/dql/JP

...
< X-Cache-Key: a3dad8528d327acbab14c19dc9057727fc1bcf0a236d2c95110a174919507dbb
< X-Cache-Status: Miss
< X-Kong-Upstream-Latency: 174
< X-Kong-Proxy-Latency: 12
...
* Connection #0 to host localhost left intact
{"data":{"country":{"name":"Japan","native":"日本","capital":"Tokyo","emoji":"🇯🇵","currency":"JPY","languages":[{"code":"ja","name":"Japanese"}]}}}%                                                                                 
```

首次请求会访问后端 GraphQL API 并返回响应。此时还没有缓存，`X-Cache-Status: Miss`，延迟 174ms。

再次请求同样内容：

```sh
curl -vvv -X GET http://localhost:8000/dql/JP
...
< X-Cache-Key: a3dad8528d327acbab14c19dc9057727fc1bcf0a236d2c95110a174919507dbb
< X-Cache-Status: Hit
< X-Kong-Upstream-Latency: 0
< X-Kong-Proxy-Latency: 1
...
* Connection #0 to host localhost left intact
{"data":{"country":{"name":"Japan","native":"日本","capital":"Tokyo","emoji":"🇯🇵","currency":"JPY","languages":[{"code":"ja","name":"Japanese"}]}}}%                                                                                  
```

`X-Cache-Status: Hit` 说明缓存生效，响应直接由 Kong 返回。`< X-Kong-Upstream-Latency: 0` 表示未访问上游 API，延迟为 0ms。

#### 缓存操作

可用插件提供的 API Endpoint 检查和删除缓存。详见 `https://docs.konghq.com/hub/kong-inc/graphql-proxy-cache-advanced/api/#managing-cache-entities`。

利用 GraphQL Proxy Caching Advanced 可提升 GraphQL API 性能：

- **请求缓存加速响应，减轻后端压力**
- **合理设置缓存策略和 TTL，平衡数据新鲜度与性能**
- **灵活绕过和清理缓存，便于管理**

## GraphQL Rate Limiting Advanced 插件介绍

GraphQL Rate Limiting Advanced 是 Kong 的 GraphQL API 高级限流插件。可防止过量请求，减轻 API 服务压力。

### 主要功能

- **请求数限制**：限制特定时间段内的请求数，防止服务过载
- **按用户限流**：可为每个用户单独设置限流
- **动态限流**：可灵活调整请求限制

### GraphQL Rate Limiting Advanced Demo

#### 启用插件

首先为目标 Service 启用 GraphQL Rate Limiting Advanced。

```bash
curl -i -X POST http://localhost:8001/services/countries-graphql/plugins \
  --data name=graphql-rate-limiting-advanced \
  --data config.limit=3,100 \
  --data config.window_size=60,3600 \
  --data config.sync_rate=1
```

本例配置为每分钟最多 3 次、每小时最多 100 次请求。

## 总结

通过 Kong，可以更高效地管理 GraphQL API，提升安全性和性能。用 DeGraphQL 插件可像 REST 一样操作 GraphQL，结合限流和缓存插件可管理负载、提升可用性并减少运维压力。

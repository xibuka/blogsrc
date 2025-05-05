---
title: "Kong gateway 入门 - 利用缓存提升性能"
date: 2024-12-06T23:49:19+09:00
draft: false
tags:
- kong
- Caching
---

## 前言

在 API 网关中使用缓存的主要目的如下：

- 响应速度快
- 降低后端负载
- 节省成本

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/6ed481cd-b8b3-c503-71cb-4cc8d67bef65.png)

**上方（第一次请求）流程：**

1. 客户端向 Kong Gateway 发送请求
2. Kong Gateway 将请求转发到后端（上游服务）
3. Kong Gateway 收到后端响应，并将其作为响应缓存保存
4. 将响应返回给 Consumer

**下方（第二次请求）流程：**

1. 客户端再次发送相同请求
2. Kong Gateway 检查缓存，直接返回已保存的响应
3. 此时无需访问后端，响应速度大幅提升
4. 只要 TTL（缓存有效期）未过期，该缓存即可被使用

Kong 的缓存功能通过插件实现。只需启用插件并进行必要配置，即可轻松使用缓存。你可以精细控制缓存的有效期和目标数据，满足不同场景需求。此外，缓存本身也可以外部存储，即使在大规模系统中也能高效运行，并与 Kong 的高可扩展性结合。

## 缓存的基本概念

缓存是一种临时存储频繁访问数据、以实现高速响应的机制。大部分缓存数据存储在内存（RAM）中，响应极快。缓存包含以下三要素：

1. 缓存键：用于标识存储数据的唯一标识符
2. 缓存数据：实际存储的响应数据
3. TTL（Time-To-Live）：数据的有效期

## Kong Gateway 提供的缓存功能

Kong 提供了两种缓存插件：

[Proxy Caching](https://docs.konghq.com/hub/kong-inc/proxy-cache/)
[Proxy Caching Advanced](https://docs.konghq.com/hub/kong-inc/proxy-cache-advanced/)

### Proxy Caching

Proxy Caching 插件会缓存 HTTP 响应，对后续相同请求直接返回缓存数据，从而最小化对后端服务的访问，提高 API 性能。

首先，创建测试用 Service 和 Route。

```bash
curl -i -X POST http://localhost:8001/services/ \
  --data name=uuid_service \
  --data url=http://httpbin.org/uuid

curl -i -X POST http://localhost:8001/services/uuid_service/routes/ \
  --data name=uuid_route \
  --data paths=/uuid 
```

然后，为 Service 创建 Proxy Caching 插件。

#### 插件配置

```bash
curl -X POST http://localhost:8001/services/uuid_service/plugins \
  --data "name=proxy-cache" \
  --data "config.strategy=memory" 
```

该命令会为 `uuid_service` Service 注册如下配置：

- 插件：Proxy Cache
- 缓存存储位置：内存（Memory）

#### 动作验证

首先发送第一次请求。

```bash
curl -v http://localhost:8000/uuid
...（输出省略）
{
  "uuid": "d93f8bf3-e610-48bf-81a7-ae656e7d868c"
}
```

查看响应：

- X-Cache-Key：每个请求计算的缓存键，详细算法见[这里](https://docs.konghq.com/hub/kong-inc/proxy-cache/#cache-key)
- X-Cache-Status：缓存状态。第一次请求还未缓存，显示为 `Miss`
- X-Kong-Upstream-Latency：Kong 到上游 API 的延迟。需要访问后端，耗时 480ms

接着，同一客户端再次发送相同请求。

```bash
curl -v http://localhost:8000/uuid
...（输出省略）
{
  "uuid": "d93f8bf3-e610-48bf-81a7-ae656e7d868c"
}
```

与第一次响应对比：

- X-Cache-Key：相同请求，键相同
- X-Cache-Status：第二次请求，响应已缓存，显示为 `Hit`
- X-Kong-Upstream-Latency：无需访问上游 API，延迟为 0ms

结果是，原本 480ms 的延迟被缩短为 0ms，响应时间大幅提升。

#### 内存缓存的局限

Kong Gateway 的缓存若存储在**内存**，单节点环境下没问题，但多节点环境下会有如下隐患：

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/d8175cd4-b550-ff75-4e1c-96b94d2e6c46.png)

- 每个节点有独立内存，缓存数据仅存于本地
- 客户端在多节点间负载均衡时，节点间缓存不共享，部分请求会出现缓存未命中（Miss）
- 节点重启后，内存缓存全部丢失，后端负载可能骤增

为解决此问题，需在节点间共享缓存。OSS 版 Proxy Caching 仅支持内存，Proxy Caching Advanced 则支持内存和 Redis。

### Proxy Caching Advanced

Kong Gateway 的 Proxy Caching Advanced 插件支持将缓存存储在 Redis，实现多节点间缓存共享，提升一致性和性能。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/39f5e640-2422-e406-d720-4740bf0f8452.png)

#### 插件配置

使用 Redis 时的主要配置项如下：

| 配置项         | 说明                         | 示例        |
|:--------------|:----------------------------|:-----------|
| strategy      | 缓存存储方式                | redis      |
| redis.host    | Redis 服务器主机名或 IP     | 127.0.0.1  |
| redis.port    | Redis 服务器端口            | 6379       |
| redis.password| 连接 Redis 的密码           | kong       |

```bash
curl -X POST http://localhost:8001/services/uuid_service/plugins \
  --data "name=proxy-cache-advanced" \
  --data "config.strategy=redis" \
  --data "config.redis.host=18.178.66.113" \
  --data "config.redis.port=6379" \
  --data "config.redis.password=kong" 
```

#### 动作验证

配置完成后，与前述方法一样，连续两次请求同一接口，第二次响应时间会明显缩短。

```bash
curl -v http://localhost:8000/uuid
...（输出省略）
{
  "uuid": "58c02bf6-4437-4720-aa8d-a41d30677ba6"
}
curl -v http://localhost:8000/uuid
...（输出省略）
{
  "uuid": "58c02bf6-4437-4720-aa8d-a41d30677ba6"
}
```

## 总结

本文介绍了 Kong Gateway 的缓存原理及用法。实测命中缓存时响应时间大幅缩短。单节点环境下可用内存缓存，多节点环境建议用 Proxy Caching Advanced 配合 Redis。

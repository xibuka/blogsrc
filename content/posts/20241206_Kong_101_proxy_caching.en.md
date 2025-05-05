---
title: "Kong Gateway Introduction - Boosting Performance with Caching"
date: 2024-12-06T23:49:19+09:00
draft: false
tags:
- kong
- Caching
---

## Introduction

The main purposes of caching in an API gateway are as follows:

- Fast response
- Reduced backend load
- Cost savings

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/6ed481cd-b8b3-c503-71cb-4cc8d67bef65.png)

**First request flow (upper section):**

1. The client sends a request to Kong Gateway
2. Kong Gateway forwards the request to the backend (upstream service)
3. Kong Gateway receives the response from the backend and saves it as a response cache
4. The response is returned to the consumer

**Second request flow (lower section):**

1. The client sends the same request again
2. Kong Gateway checks the cache and directly returns the stored response
3. In this case, there is no need to access the backend, so the response speed is greatly improved
4. As long as the TTL (cache expiration) has not expired, this cache can be used

Kong's caching feature is implemented via plugins. By simply enabling the plugin and configuring the necessary settings, you can easily use caching. You can finely control the cache duration and target data, allowing for use-case-specific configurations. Furthermore, the cache itself can be stored externally, making it effective even in large-scale systems and leveraging Kong's high scalability.

## Basic Concepts of Caching

Caching is a mechanism that temporarily stores frequently accessed data for fast delivery. Most cache data is stored in RAM, enabling extremely fast responses. Caching consists of the following three components:

1. Cache key: An identifier to specify the stored data
2. Cache data: The actual response data being stored
3. TTL (Time-To-Live): The expiration time of the data

## Caching Features Provided by Kong Gateway

Kong provides two plugins for caching:

[Proxy Caching](https://docs.konghq.com/hub/kong-inc/proxy-cache/)
[Proxy Caching Advanced](https://docs.konghq.com/hub/kong-inc/proxy-cache-advanced/)

### Proxy Caching

The Proxy Caching plugin caches HTTP responses and directly returns cached data for subsequent identical requests. This minimizes backend service access and improves API performance.

First, create a test Service and Route.

```bash
curl -i -X POST http://localhost:8001/services/ \
  --data name=uuid_service \
  --data url=http://httpbin.org/uuid

curl -i -X POST http://localhost:8001/services/uuid_service/routes/ \
  --data name=uuid_route \
  --data paths=/uuid 
```

Next, create the Proxy Caching plugin for the Service.

#### Plugin Configuration

```bash
curl -X POST http://localhost:8001/services/uuid_service/plugins \
  --data "name=proxy-cache" \
  --data "config.strategy=memory" 
```

This command registers the following settings for the `uuid_service` Service:

- Plugin: Proxy Cache
- Cache storage: Memory

#### Operation Check

First, send the initial request.

```bash
curl -v http://localhost:8000/uuid
... (output omitted for brevity)
{
  "uuid": "d93f8bf3-e610-48bf-81a7-ae656e7d868c"
}
```

Check the response:

- X-Cache-Key: The cache key calculated per request. See [here](https://docs.konghq.com/hub/kong-inc/proxy-cache/#cache-key) for details
- X-Cache-Status: The cache status. Since this is the first request, the response is not yet cached, so it's `Miss`
- X-Kong-Upstream-Latency: Latency from Kong to the upstream API. Since access is needed, it took 480ms

Next, send the same request again from the same client.

```bash
curl -v http://localhost:8000/uuid
... (output omitted for brevity)
{
  "uuid": "d93f8bf3-e610-48bf-81a7-ae656e7d868c"
}
```

Compared to the first response:

- X-Cache-Key: Same key for the same request
- X-Cache-Status: Since this is the second request, the response is cached and available, so it's `Hit`
- X-Kong-Upstream-Latency: No need to access the upstream API, so it's 0ms

As a result, the latency, which was originally 480ms, is reduced to 0ms, greatly shortening the response time.

#### Issues with Storing Cache in Memory

When storing Kong Gateway's cache in **memory**, it's fine for single-node setups, but in multi-node environments, the following concerns arise:

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/d8175cd4-b550-ff75-4e1c-96b94d2e6c46.png)

- Each node has its own memory, and cache data is stored locally on each node
- If clients are load balanced across multiple nodes, cache is not shared between nodes, so some requests may result in cache misses
- If a node is restarted, all memory cache data is lost, potentially causing a sudden increase in backend load

To solve this, cache needs to be shared between nodes. The OSS Proxy Caching plugin only supports memory, but Proxy Caching Advanced supports both memory and Redis.

### Proxy Caching Advanced

The Proxy Caching Advanced plugin in Kong Gateway allows you to store cache in Redis, enabling cache sharing across multiple nodes and consistent performance improvements.

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/39f5e640-2422-e406-d720-4740bf0f8452.png)

#### Plugin Configuration

The main settings when using Redis are as follows:

| Setting      | Description                              | Example      |
|:------------ |:-----------------------------------------|:------------|
| strategy     | Cache storage method                     | redis       |
| redis.host   | Redis server hostname or IP address      | 127.0.0.1   |
| redis.port   | Redis server port                        | 6379        |
| redis.password | Password for connecting to Redis server | kong        |

```bash
curl -X POST http://localhost:8001/services/uuid_service/plugins \
  --data "name=proxy-cache-advanced" \
  --data "config.strategy=redis" \
  --data "config.redis.host=18.178.66.113" \
  --data "config.redis.port=6379" \
  --data "config.redis.password=kong" 
```

#### Operation Check

After setting the above, as with the previous method, sending the same request twice will result in a shorter response time for the second access.

```bash
curl -v http://localhost:8000/uuid
... (output omitted for brevity)
{
  "uuid": "58c02bf6-4437-4720-aa8d-a41d30677ba6"
}
curl -v http://localhost:8000/uuid
... (output omitted for brevity)
{
  "uuid": "58c02bf6-4437-4720-aa8d-a41d30677ba6"
}
```

## Summary

This article explained caching in Kong Gateway and how to use it. We confirmed that response time is reduced when the cache is hit. For single-node setups, storing cache in memory is fine, but for multi-node environments, use Proxy Caching Advanced with Redis.

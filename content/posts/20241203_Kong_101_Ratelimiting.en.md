---
title: "Kong API Gateway Introduction - Getting Started with Kong Gateway: How to Implement Rate Limiting"
date: 2024-12-03T23:49:19+09:00
draft: false
tags:
- kong
- RateLimiting
---

## The Importance of Rate Limiting

In today's API economy, rate limiting plays a crucial role in system stability, security, and cost efficiency. Here's a detailed explanation of its importance.

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/fa88a4e5-e1dc-e2b9-c1fc-a93b16ab9b6d.png)

### Server Load Management

APIs can receive unpredictable amounts of requests. For example, a sudden surge in popularity or unexpected traffic spikes can overload servers. By setting rate limits, you can control the maximum number of requests and ensure the server maintains proper performance.

### Ensuring Fairness

Rate limiting is an important way to ensure all users can access the API fairly. It prevents specific users or applications from monopolizing resources and protects the experience of other users.

### Enhancing Security

Rate limiting is effective against malicious requests, DoS (Denial of Service) attacks, and unauthorized bot access. By detecting and limiting abnormal request patterns, you can protect your API and the entire system.

### Cost Management

Many cloud providers and infrastructure services charge based on the number of requests or data transfer. Allowing unlimited requests can lead to unexpected cost spikes. By setting rate limits, you can better predict costs and avoid unnecessary expenses.

## Basic Mechanism of Rate Limiting in Kong

Kong Gateway is an open-source API gateway that makes it easy to manage and protect APIs. It is used by companies and developers to improve API security, performance, and reliability. Rate limiting in Kong Gateway is a feature for controlling traffic to API endpoints. This feature is provided as a plugin and can be easily enabled and configured.

Kong's rate limiting plugin works as follows:

1. **Request Counting**
   The plugin counts requests and applies limits if the number of requests exceeds the allowed range within a specified time frame (seconds, minutes, hours, days, etc.).
2. **Behavior When Exceeding Thresholds**
   Requests that exceed the allowed range are rejected with an HTTP status code (usually 429 Too Many Requests). You can also set a custom message.
3. **Use of Storage**
   To store count information, local memory or external storage like Redis is used. This ensures consistency in distributed environments.
4. **Flexible Scope of Application**
   - Per Service: Set limits for specific APIs
   - Per Consumer: Apply different limits for individual users or applications
   - Per Route: Set limits only for specific API endpoints

## Basic Setup: Kong Rate Limiting Plugin

Kong provides two rate limiting plugins. Both limit the number of requests per time unit. For example, you can easily set a limit of 3 requests per minute.

- [OSS] `https://docs.konghq.com/hub/kong-inc/rate-limiting/`
- [Enterprise] `https://docs.konghq.com/hub/kong-inc/rate-limiting-advanced/`

### Plugin Setup

This blog will first explain the OSS version. First, create a test Service and Route.

```bash
curl -i -X POST http://localhost:8001/services/ \
  --data name=uuid_service \
  --data url=http://httpbin.org/uuid

curl -i -X POST http://localhost:8001/services/uuid_service/routes/ \
  --data name=uuid_route \
  --data paths=/uuid 
```

Without any limits, you can generate unlimited UUIDs.

```bash
curl http://localhost:8000/uuid
{
  "uuid": "84677e6f-911c-457b-a74f-d825e84248cb"
}
```

Next, create a Rate Limiting plugin for the Service.

```bash
curl -X POST http://localhost:8001/services/uuid_service/plugins \
    --data "name=rate-limiting" \
    --data "config.minute=5"
```

This command registers the following settings for the `uuid_service` Service:

- Plugin: Rate Limiting
- Limit: Maximum 5 accesses per minute

If you want to apply the limit to a Route or Consumer, change the `services/uuid_service` part accordingly.

### Operation Check

The first 5 accesses are allowed:

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

From the 6th request, you get an error:

```bash
curl http://localhost:8000/uuid
{
  "message":"API rate limit exceeded",
  "request_id":"090e45286c55141b7fc47640d3df482d"
}
```

## Advanced Settings

### Error Message and Response Code

To customize the error message and error code, set the following:

```bash
curl -X POST http://localhost:8001/services/uuid_service/plugins \
    --data "name=rate-limiting" \
    --data "config.minute=5" \
    --data "config.error_code=429" \
    --data "config.error_message=Please wait a moment"
```

If you access more than 5 times, you'll get the customized response.

```bash
curl -S http://localhost:8000/uuid
{
  "message":"Please wait a moment",
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

### Request Counter and Using Redis

Kong's Rate Limiting plugin provides a flexible mechanism for storing request counters in a database, memory, or Redis. Each storage method has its characteristics, and you should choose based on your environment.

#### Storing in Database

If you store counters in a database, all Kong nodes must connect to the database. This allows consistent count sharing between nodes. However, it does not work in dbless or hybrid mode.

#### Storing in Memory

This is suitable for single-node environments where speed is required. It is limited in distributed environments.

#### Storing in Redis

Using Redis allows counters to be shared across the entire cluster. All Kong nodes refer to the same Redis instance, enabling accurate counting across the cluster. Redis's performance also supports large-scale traffic. However, using Redis requires setup effort and countermeasures for Redis failures.

#### Example: Using Redis

Use the following file to set up a Redis environment with docker compose. The `"--requirepass kong"` part sets the Redis password.

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

Set up Rate Limiting with the following command:

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

- `config.policy=redis`: Store counters in Redis
- `config.host`: Redis hostname
- `config.port`: Redis port
- `config.username`: Username for Redis access (default is `default`)
- `config.password`: Password for Redis access (here, `kong`)

After sending some requests, you can check the counters in Redis with the following commands:

```bash
# Enter the Redis container
> docker exec -it 51 sh

# Log in with the password
> redis-cli -a kong

# Send a request and list keys
127.0.0.1:6379> keys *
1) "ratelimit:00000000-0000-0000-0000-000000000000:628a172c-a98f-4355-a09b-f78f8e7f2562:172.21.0.1:1733231580000:minute"

# Check the value of this key, should be 1
127.0.0.1:6379> get ratelimit:00000000-0000-0000-0000-000000000000:628a172c-a98f-4355-a09b-f78f8e7f2562:172.21.0.1:1733231580000:minute
"1"
```

### Changing Limits by Time

By combining Pre-function and Rate Limiting, you can change the rate limit count based on the time. In practice, you create two Routes for one Service, each with different header conditions. By using a Pre-function to set different headers based on the time, you can achieve this functionality.

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/bc2c03f6-2bd3-24bd-9cc9-5d56c3967ef4.png)

First, create a test Service.

```bash
curl -i -X POST http://localhost:8001/services \
  --data "name=httpbin" \
  --data "url=https://httpbin.konghq.com/anything"
```

Next, create two Routes. The paths are the same, but the header conditions differ.

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

Then, set up Rate Limiting plugins for each Route.

```bash
curl -i -X POST http://localhost:8001/routes/peak/plugins/  \
   --data "name=rate-limiting" \
   --data "config.minute=10" 

curl -i -X POST http://localhost:8001/routes/off-peak/plugins/  \
   --data "name=rate-limiting" \
   --data "config.minute=60" 
```

Finally, use a Pre-function to set headers so that traffic is routed to the correct Route based on the time.

Save the following as `ratelimit.lua`. This function determines the time based on the OS clock and sets the appropriate header (`X-Peak` or `X-Off-Peak`) based on the time (08:00 - 17:00).

```ratelimit.lua
local hour = os.date("*t").hour 
if hour >= 8 and hour <= 17 
then
    kong.service.request.set_header("X-Peak","true") 
else
    kong.service.request.set_header("X-Off-Peak","true") 
end
```

Set this code to run in the rewrite phase:

```bash
curl -i -X POST http://localhost:8001/plugins \
    --form "name=pre-function" \
    --form "config.rewrite[1]=@ratelimit.lua"
```

With this, you can achieve 10 requests/minute during business hours (08:00 - 17:00) and 60 requests/minute outside business hours.

## Differences Between OSS and Enterprise

The [Rate Limiting Advanced documentation](https://docs.konghq.com/hub/kong-inc/rate-limiting-advanced/) describes the differences from the OSS plugin:

- Multiple Limits and Window Sizes
  - For example, if you set a limit of 1000 requests per day, but all 1000 are sent in the last minute, it can overload the API. With multiple limits (e.g., 1000/day + 60/minute), you can solve this problem.
- Support for Redis Sentinel, Redis cluster, and Redis SSL
- Better throughput and accuracy
- More rate limiting algorithms
- Support for Consumer groups

## Conclusion

This article explained the importance of rate limiting in Kong Gateway, its basic mechanism, and how to configure it. Rate limiting is a key technology for stable API operation, security, and cost management. Thanks to Kong's flexible plugin design, you can use this feature easily and efficiently.

The OSS version of Kong is sufficient for most needs, but for more complex requirements, consider using the Enterprise version, which offers additional features and improved performance for enterprise needs.

I hope this article helps you manage APIs with Kong. Stay tuned for more technical blog posts on API and microservices operations!

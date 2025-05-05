---
title: "Make Request Processing Smarter with Kong's Serverless Feature"
date: 2025-04-15T23:49:19+09:00
draft: false
tags:
- kong
- ServerLess
---

## Pre-function Plugin Explained with Practical Example

Kong Gateway is a multifunctional API gateway, but did you know you can embed **lightweight serverless functions** directly inside it?

This time, we'll introduce a practical example using Lua scripts to **extract a UUID from the request body, add it to the header, and output it to the log**.

---

## What is the Pre-function Plugin?

As described in the [official documentation](https://docs.konghq.com/hub/kong-inc/pre-function/), the `pre-function` plugin is a flexible feature that allows you to **write Lua code to process requests before they are sent to the API**.

It can be used for:

- Conditional filtering
- Customizing headers/bodies
- Lightweight logging or monitoring
- Simple maintenance blocking

It's perfect for cases where you don't need a full plugin, but want to do "just a little processing".

---

## Practical Example

This time, we'll use the serverless feature to extract a UUID from the request body and add it to the header and log.

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/4c10fa10-6a82-4108-adde-dfba074b1dbc.png)

### Processing Flow

1. Extract UUID from the request body (parse JSON)
2. If a UUID exists, add it to the `x-uuid` header
3. Output the extraction result to the log (using the File Log plugin)

---

### Preparation: Create Service and Route

```bash
# Create service
curl -i -X POST http://localhost:8001/services \
  --data name=mock-service \
  --data url=http://httpbin.org/anything

# Create route
curl -i -X POST http://localhost:8001/services/mock-service/routes \
  --data 'paths[]=/uuid-test'
```

### Output Log with File Log Plugin (to stdout)

```bash
curl -i -X POST http://localhost:8001/services/mock-service/plugins \
  --data "name=file-log" \
  --data "config.path=/dev/stdout"
```

### Pre-function Configuration

You can execute custom code at each Nginx phase. For details on phases, see:
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

The above code inserts the following into the `access` and `log` phases. Comments explain each part:

```lua
-- Extract body from request
local body, err, mimetype = kong.request.get_body()

-- If uuid exists in body, add it to the header
if body.uuid ~= nil then
  kong.service.request.add_header('uuid', body.uuid)
end

-- Add body content to the log
kong.service.request.enable_buffering()
kong.log.set_serialize_value('request.body', kong.request.get_body())
```

```lua
-- Add response content to the log
kong.log.set_serialize_value('response.body', kong.service.response.get_body())
```

## Sending a Request

Send a request with `uuid` in the body.

```json
curl -i -X POST http://localhost:8000/uuid-test \
  -H "Content-Type: application/json" \
  -d '{"uuid": "123e4567-e89b-12d3-a456-426614174000"}'
```

When the API is reached, the header will include `"Uuid": "123e4567-e89b-12d3-a456-426614174000"`.

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

From the log, you can see the details of the request and response, including both the header and the body.

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

## Conclusion

By combining Kong's pre-function and file-log plugins, you can process and visualize API request content without calling external services.

Kong can be used as more than just a gateway—it can serve as a "lightweight edge processing engine." With Lua scripts, you can smartly automate preprocessing for REST APIs!

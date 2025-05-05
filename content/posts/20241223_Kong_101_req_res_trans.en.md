---
title: "How to Freely Customize Requests and Responses with Kong Gateway"
date: 2024-12-23T23:49:19+09:00
draft: false
tags:
- kong
---

## Introduction

In modern application development, APIs are a crucial foundation for integrating with other systems and services. However, challenges such as mismatched API requirements, differing data formats, and unmet security requirements frequently arise between different systems. In such situations, leveraging an API gateway is the most effective way to flexibly modify requests and responses.

An API gateway like Kong Gateway is more than just an API management tool. It provides powerful features to customize the content of requests and responses as it controls the flow of traffic. For example, you can modify the following items:

- Headers
  You can add authentication information or custom values to request headers sent from clients, or edit response headers to include cache control or security information.
  
- Body transformation
  You can modify the request body to match the format expected by upstream services, or filter the response body to remove unnecessary data.
  
- Status code changes
  You can change the status code according to API behavior to control error handling or redirect behavior.
  
- Data format conversion
  If an old system requires XML but a new system uses JSON, you can ensure compatibility by dynamically converting data formats at the API gateway.
  
- Encryption and decryption
   Depending on security requirements, you can encrypt or decrypt request and response data to enhance communication security.

All these changes can be made without modifying API clients or backends. Since the API gateway operates at the system boundary, it enables flexible customization while minimizing the risk of affecting other systems.

## How to Modify Requests and Responses with Kong

This article explains in detail how to achieve these changes with Kong Gateway.

### Introduction to the Request Transformer / Response Transformer Plugins

The [Request Transformer](https://docs.konghq.com/hub/kong-inc/request-transformer/) and [Response Transformer](https://docs.konghq.com/hub/kong-inc/response-transformer/) plugins provided by Kong Gateway are tools for easily customizing the content of requests and responses. By using these plugins, you can process and transform request and response headers and bodies, which is useful for system integration and meeting specific API requirements.

#### Main Features

Request Transformer plugin main features:

- Add, remove, or overwrite request headers
- Add, remove, or overwrite query parameters
- Add or remove request body fields

Response Transformer plugin main features:

- Add, remove, or overwrite response headers
- Remove unnecessary parts of the response body

By combining these features, you can flexibly control API traffic.

#### Plugin Configuration

First, create a test Service and Route. Here, we use an API that echoes the request as the response, so you can check the modified request.

```bash
curl -i -X POST http://localhost:8001/services/ \
  --data name=echo_service \
  --data url=http://httpbin.org/anything

curl -i -X POST http://localhost:8001/services/echo_service/routes/ \
  --data name=echo_route \
  --data paths=/echo 
```

Next, enable the request transformer plugin and set the following rules:

- Add Authorization header
- Remove debug query parameter

```bash
curl -i -X POST http://localhost:8001/services/echo_service/plugins \
    --data "name=request-transformer" \
    --data "config.add.headers=Authorization: Bearer abc123" \
    --data "config.remove.querystring=debug"
```

#### Operation Check

After sending the following request:

```bash
http localhost:8000/echo\?debug=aaa\&uuid=2345
```

you will receive the following response:

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

As you can see, the request was modified as configured:

- The header `"Authorization": "Bearer abc123",` was added
- The URL param `debug=aaa` was removed

There are many other things you can do, so please refer to the [plugin page](https://docs.konghq.com/hub/kong-inc/request-transformer/how-to/basic-example/) for more information.

### exit transformer

The [exit transformer](https://docs.konghq.com/hub/kong-inc/exit-transformer/) plugin uses Lua functions to transform and customize Kong Gateway's response termination messages. This plugin can change messages, status codes, headers, and even completely transform the entire structure of Kong Gateway responses.

This plugin executes the configured code when a 4xx or 5xx response is returned.

:::note warn
Currently, this plugin only responds to internal Kong errors and does not handle errors from upstream.
:::

#### exit transformer Plugin Configuration

First, register a test service and route.

```bash
 curl -i -X POST http://localhost:8001/services \
   --data name=example.com \
   --data url='https://httpbin.konghq.com'

curl -i -X POST http://localhost:8001/services/example.com/routes \
   --data 'paths=/example'
```

Enter the script that the plugin will execute as shown below, and save it as `transform.lua`.

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

This script makes the following changes:

- Adds `["x-some-header"] = "some value"` to the headers
- Appends `arr` to the end of the body message
- Forces the response status code to `200`

Now, enable the `exit-transformer` plugin using the above `transform.lua`.

```bash
 curl -X POST http://localhost:8001/services/example.com/plugins \
   -F "name=exit-transformer"  \
   -F "config.functions=@transform.lua"
```

Add key-auth to trigger an error response.

```bash
 curl -X POST http://localhost:8001/services/example.com/plugins \
   --data "name=key-auth"
```

#### exit transformer Operation Check

Send a request to `/example` to get a custom error. In this case, since the request does not provide authentication (API key), a 401 response is returned in the message body, but the client receives a 200 response.

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

## Conclusion

API gateways are essential tools for flexibly adapting to integration and requirements between different systems. With Kong Gateway, you can dynamically modify request and response headers, bodies, and status codes, as well as perform data format conversions and enhance security. By leveraging standard plugins and Lua scripts, you can greatly improve the flexibility and efficiency of your entire system.

---
title: "Kong API Gateway Introduction - Understanding Service and Route: From Basics to Advanced"
date: 2024-12-01T23:49:19+09:00
draft: false
tags:
- kong
---

When using Kong Gateway, "Service" and "Route" play crucial roles. A Service defines the destination for API requests, while a Route specifies the rules for mapping those requests to the Service.

## What is a Service?

A Service defines the information of an external API or microservice that Kong Gateway proxies. Specifically, you configure the destination URL, hostname, port, protocol, etc., to which requests are forwarded.

For example, if you want to proxy a backend "User API" with Kong, you register that API as a Service. Kong receives requests from clients and forwards them to the registered Service. The main settings when creating a Service in Kong are as follows:

- name: The name of the Service. Functions as a label for identification
- host: The hostname to which requests are forwarded (e.g., example.com)
- port: The destination port (default: 80 or 443)
- protocol: The protocol to use (http or https)
- path: A specific path to forward to (e.g., /api/v1/users)

## What is a Route?

A Service does not function alone; it is used in conjunction with a "Route." A Route is a configuration that maps client requests to a specific Service. You can specify conditions such as:

- Path: The URL path clients access
- Method: HTTP methods (e.g., GET, POST)
- Host: The request's host header
- Header: Specific HTTP header values

With Route settings, Kong determines which requests to forward to which Service.

## Practical Examples

### Building One Service and One Route

This example explains how to expose a single Service with a single Route. We'll register an external API `http://httpbin.org/uuid` as a Service in Kong Gateway and expose it at the `/uuid` path. Accessing the published endpoint will return a UUID (unique identifier).

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/1b4773ab-6970-2468-3c58-da6c1d30256d.png)

First, use the following command to create a Service targeting `http://httpbin.org/uuid`:

```bash
curl -i -X POST http://localhost:8001/services/ \
  --data name=uuid_service \
  --data url=http://httpbin.org/uuid
```

This command registers the following settings in Kong:

- Service name: uuid_service
- Upstream URL: `http://httpbin.org/uuid`

Next, create a Route to expose this Service. Use the following command to expose the Service at the `/uuid` path:

```bash
curl -i -X POST http://localhost:8001/services/uuid_service/routes/ \
  --data name=uuid_route \
  --data paths=/uuid 
```

The registered Route will have the following settings:

- Route name: uuid_route
- Exposed path: /uuid

Now, when a client sends a request to the Kong Gateway endpoint (e.g., `http://localhost:8000/uuid`), Kong will forward the request to `http://httpbin.org/uuid`.

Once everything is set up, send a request to verify the connection via Kong Gateway:

```bash
curl http://localhost:8000/uuid
{
  "uuid": "84677e6f-911c-457b-a74f-d825e84248cb"
}
```

This result confirms that Kong Gateway is correctly proxying the request.

### Building One Service and Two Routes

You can also set up two different Routes with different paths for a single Service (user-service).

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/987145e5-95e4-fdd2-63ed-0190e6b9f2cf.png)

Advantages of multiple Routes:

- Flexible API structure: Assigning different paths to a single Service allows you to customize API access for each client
- Simplified management: With multiple Routes, you can apply plugins (such as authentication or caching) per Route
- Efficient traffic control: You can set routing rules for each path, making load balancing and security management easier

The creation of uuid_service and uuid_route is the same as above, so it is omitted here.

You can create uuid_route_new with a similar command:

```bash
curl -i -X POST http://localhost:8001/services/uuid_service/routes/ \
  --data name=uuid_route_new \
  --data paths=/uuid_new
```

Once everything is set up, send requests to both Routes to verify. You should see that both are correctly proxying requests.

```bash
curl http://localhost:8000/uuid
{
  "uuid": "b25f73f6-0a77-4a06-a611-97082b0ea449"
}
curl http://localhost:8000/uuid_new
{
  "uuid": "5ba6503d-ba06-41d7-9e30-880074513d3a"
}
```

### Building One Service and Two Routes, Inheriting the Service Path in the Route

This section explains in detail how to set up two Routes for one Service, with the Route inheriting the Service's path setting.

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/acb7d09b-8d74-073d-be97-2572e0328888.png)

In this scenario, we will:

- Register a Service targeting `http://httpbin.org`
- Route 1: Expose `/uuid` as the public path, inheriting the Service's `/uuid` path
- Route 2: Expose `/ip` as the public path, inheriting the Service's `/ip` path

With this setup, the following requests are possible:

- `http://localhost:8000/uuid` → `http://httpbin.org/uuid`
- `http://localhost:8000/ip` → `http://httpbin.org/ip`

#### Register the Service

First, register the external API to be proxied as a Service. The method is the same as above, but this time register the URL with the path `/`.

```bash
curl -i -X POST http://localhost:8001/services/ \
  --data name=httpbin_service \
  --data url=http://httpbin.org
```

#### Create the uuid Route

Create the first Route and expose it at the `/uuid` path. By setting `strip_path=false`, the `/uuid` path will be appended to the Service.
`strip_path` is an important option when configuring Routes in Kong Gateway; it controls whether the path specified in the Route is removed when forwarding the request to the Service. The default is `strip_path=true`, which removes the Route path when forwarding. Setting `strip_path=false` means the Route path is preserved and forwarded to the Service.

Use the following command:

```bash
curl -i -X POST http://localhost:8001/services/httpbin_service/routes/ \
  --data name=uuid_route \
  --data paths=/uuid \
  --data strip_path=false
```

#### Create the ip Route

Use the following command to create the second Route and expose it at the `/ip` path.

```bash
curl -i -X POST http://localhost:8001/services/httpbin_service/routes/ \
  --data name=ip_route \
  --data paths=/ip \
  --data strip_path=false
```

#### Verify the Settings

Once everything is set up, send requests to the endpoints to verify operation.

##### Check the /uuid endpoint

```bash
curl http://localhost:8000/uuid
{
  "uuid": "91c0b30e-220d-4766-b41b-fc428d25f9d0"
}
```

##### Check the /ip endpoint

```bash
curl http://localhost:8000/ip
{
  "origin": "172.21.0.1, x.x.x.x"
}
```

By using `strip_path=false`, you can achieve flexible routing while preserving the path structure on the Service side.

This approach is useful in the following situations:

- When the external API provides multiple endpoints and you want to expose each at a different path
- When you want to keep the public path structure simple while leveraging the existing Service paths

## Summary

By properly configuring "Service" and "Route" in Kong Gateway, you can achieve flexible API routing. Services define information about external APIs or microservices, and Routes map client requests to those Services. Furthermore, by using `strip_path=false`, you can inherit the public path into the Service's path structure.

In future articles, we'll explain how to further enhance Kong Gateway's functionality by leveraging plugins such as authentication, rate limiting, and caching—so stay tuned!

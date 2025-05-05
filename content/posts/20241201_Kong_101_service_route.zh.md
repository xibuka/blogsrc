---
title: "Kong API Gateway 入门 - 理解 Service 和 Route：从基础到进阶"
date: 2024-12-01T23:49:19+09:00
draft: false
tags:
- kong
---

在使用 Kong Gateway 时，"Service（服务）"和"Route（路由）"扮演着至关重要的角色。Service 定义了 API 请求的转发目标，而 Route 则规定了将请求映射到 Service 的规则。

## 什么是 Service？

Service 是对 Kong Gateway 代理的外部 API 或微服务的信息定义。具体来说，你可以配置请求转发目标的 URL、主机名、端口、协议等。

例如，如果你想用 Kong 代理后端的"用户 API"，就需要将该 API 注册为 Service。Kong 会接收客户端请求，并将其转发到已注册的 Service。创建 Service 时主要配置项如下：

- name：服务名称，作为标识用的标签
- host：请求转发目标主机名（如 example.com）
- port：目标端口（默认 80 或 443）
- protocol：使用的协议（http 或 https）
- path：转发到的具体路径（如 /api/v1/users）

## 什么是 Route？

Service 不能单独工作，需与 Route 配合使用。Route 是将客户端请求映射到特定 Service 的配置。Route 可指定如下条件：

- Path：客户端访问的 URL 路径
- Method：HTTP 方法（如 GET、POST）
- Host：请求的 host 头
- Header：特定 HTTP 头的值

通过 Route 配置，Kong 能判断哪些请求转发到哪个 Service。

## 实用示例

### 构建一个 Service 和一个 Route

本例介绍如何用一个 Route 暴露一个 Service。我们将外部 API `http://httpbin.org/uuid` 注册为 Kong Gateway 的 Service，并通过 `/uuid` 路径对外暴露。访问该端点即可获取 UUID（唯一标识符）。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/1b4773ab-6970-2468-3c58-da6c1d30256d.png)

首先，使用如下命令创建以 `http://httpbin.org/uuid` 为目标的 Service：

```bash
curl -i -X POST http://localhost:8001/services/ \
  --data name=uuid_service \
  --data url=http://httpbin.org/uuid
```

该命令会在 Kong 中注册如下配置：

- 服务名：uuid_service
- 转发目标 URL：`http://httpbin.org/uuid`

接下来，为该 Service 创建 Route。用如下命令将其通过 `/uuid` 路径暴露：

```bash
curl -i -X POST http://localhost:8001/services/uuid_service/routes/ \
  --data name=uuid_route \
  --data paths=/uuid 
```

注册的 Route 包含如下配置：

- 路由名：uuid_route
- 暴露路径：/uuid

这样，客户端请求 Kong Gateway 的端点（如 `http://localhost:8000/uuid`）时，Kong 会将请求转发到 `http://httpbin.org/uuid`。

全部配置完成后，可用如下命令通过 Kong Gateway 发送请求验证：

```bash
curl http://localhost:8000/uuid
{
  "uuid": "84677e6f-911c-457b-a74f-d825e84248cb"
}
```

结果表明 Kong Gateway 已正确代理请求。

### 构建一个 Service 和两个 Route

你也可以为同一个 Service（如 user-service）配置两个不同路径的 Route。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/987145e5-95e4-fdd2-63ed-0190e6b9f2cf.png)

多 Route 的优势：

- API 结构灵活：为同一 Service 分配不同路径，可为不同客户端定制 API 访问方式
- 管理简化：有多个 Route 时，可针对每个 Route 应用插件（如认证、缓存等）
- 高效流量控制：可为不同路径设置路由规则，便于负载均衡和安全管理

uuid_service 和 uuid_route 的创建与上文相同，这里省略。

uuid_route_new 可用类似命令创建：

```bash
curl -i -X POST http://localhost:8001/services/uuid_service/routes/ \
  --data name=uuid_route_new \
  --data paths=/uuid_new
```

全部配置完成后，分别请求两个 Route 进行验证，均可正确代理请求。

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

### 构建一个 Service 和两个 Route，并让 Route 继承 Service 的 Path

本节详细介绍如何为一个 Service 配置两个 Route，并让 Route 继承 Service 的 path 设置。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/acb7d09b-8d74-073d-be97-2572e0328888.png)

本场景下配置如下：

- 注册以 `http://httpbin.org` 为目标的 Service
- Route 1：以 `/uuid` 为公开路径，继承 Service 的 `/uuid` 路径
- Route 2：以 `/ip` 为公开路径，继承 Service 的 `/ip` 路径

这样可实现如下请求：

- `http://localhost:8000/uuid` → `http://httpbin.org/uuid`
- `http://localhost:8000/ip` → `http://httpbin.org/ip`

#### 注册 Service

首先注册要代理的外部 API 为 Service。方法同上，这次 URL 注册为 `/`。

```bash
curl -i -X POST http://localhost:8001/services/ \
  --data name=httpbin_service \
  --data url=http://httpbin.org
```

#### 创建 uuid Route

创建第一个 Route，通过 `/uuid` 路径暴露。设置 `strip_path=false`，则 `/uuid` 路径会追加到 Service 后。
`strip_path` 是 Kong Gateway 配置 Route 时的重要选项，控制转发到 Service 时是否去除 Route 指定的路径。默认 `strip_path=true`，即转发时会去除 Route 路径。设置为 `strip_path=false`，则 Route 路径会保留并转发到 Service。

命令如下：

```bash
curl -i -X POST http://localhost:8001/services/httpbin_service/routes/ \
  --data name=uuid_route \
  --data paths=/uuid \
  --data strip_path=false
```

#### 创建 ip Route

用如下命令创建第二个 Route，通过 `/ip` 路径暴露：

```bash
curl -i -X POST http://localhost:8001/services/httpbin_service/routes/ \
  --data name=ip_route \
  --data paths=/ip \
  --data strip_path=false
```

#### 验证配置

全部配置完成后，分别请求端点进行验证。

##### 验证 /uuid 端点

```bash
curl http://localhost:8000/uuid
{
  "uuid": "91c0b30e-220d-4766-b41b-fc428d25f9d0"
}
```

##### 验证 /ip 端点

```bash
curl http://localhost:8000/ip
{
  "origin": "172.21.0.1, x.x.x.x"
}
```

通过 `strip_path=false`，可以在保留 Service 端路径结构的同时实现灵活路由。

此方法适用于如下场景：

- 外部 API 提供多个端点，希望分别以不同路径对外暴露
- 希望对外路径结构简洁，同时复用 Service 现有路径

## 总结

通过合理配置 Kong Gateway 的"Service"和"Route"，可以实现灵活的 API 路由。Service 定义外部 API 或微服务的信息，Route 则将客户端请求映射到对应 Service。此外，利用 `strip_path=false`，可以让公开路径继承到 Service 的路径结构。

后续将介绍如何通过认证、限流、缓存等插件进一步增强 Kong Gateway 的功能，敬请期待！

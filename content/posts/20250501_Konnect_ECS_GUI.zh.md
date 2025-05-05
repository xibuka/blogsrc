---
title: "用 Konnect + AWS ECS 构建 API Gateway 环境"
date: 2025-05-01T23:49:19+09:00
draft: false
tags:
- kong
- Konnect
- ECS
---

本文介绍如何以 [Kong Konnect](https://konghq.com/kong-konnect/) 作为 Data Plane，利用 AWS ECS（Elastic Container Service）Fargate 部署微服务，构建 API Gateway 环境。

## 准备工作

- AWS 账号
- Kong Konnect 账号

## 搭建步骤

### Konnect 侧操作

登录 [Konnect](https://cloud.konghq.com/us/overview/)，依次进入 `Gateway manager` -> `Data Plane Nodes` -> `Configure data plane`，点击 `Generate Certificate` 生成 docker run 命令。请复制该命令中的参数，后续会用到。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/c869a45c-04df-4f70-ac9e-8c23757429d0.png)

证书生成后，Konnect 侧操作完成。证书和 key 默认带有换行，为了作为 ECS 环境变量设置，可用如下命令转为一行：

```bash
awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' tls.key
```

### AWS ECS 侧操作

#### 容器定义

进入 `AWS ECS` -> `Task definitions` -> `Create new task definition with JSON`，进行容器定义。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/6dd7ead4-3cf4-47b1-8e31-f8a15ca0891a.png)

使用如下 JSON：

```json
{
  "family": "kong-data-plane",
  "networkMode": "awsvpc",
  "containerDefinitions": [
    {
      "name": "kong-data-plane",
      "image": "kong/kong-gateway:3.10",
      "essential": true,
      "environment": [
        { "name": "KONG_ROLE", "value": "data_plane" },
        { "name": "KONG_DATABASE", "value": "off" },
        { "name": "KONG_VITALS", "value": "off" },
        { "name": "KONG_CLUSTER_MTLS", "value": "pki" },
        { "name": "KONG_CLUSTER_CONTROL_PLANE", "value": "xxxxxxxxxxxx.us.cp0.konghq.com:443" },
        { "name": "KONG_CLUSTER_SERVER_NAME", "value": "xxxxxxxxxxxx.us.cp0.konghq.com" },
        { "name": "KONG_CLUSTER_TELEMETRY_ENDPOINT", "value": "xxxxxxxxxxxx.us.tp0.konghq.com:443" },
        { "name": "KONG_CLUSTER_TELEMETRY_SERVER_NAME", "value": "xxxxxxxxxxxx.us.tp0.konghq.com" },
        { "name": "KONG_CLUSTER_CERT", "value": "<CERT in one line>" },
        { "name": "KONG_CLUSTER_CERT_KEY", "value": "<CERT key in one line>" },
        { "name": "KONG_LUA_SSL_TRUSTED_CERTIFICATE", "value": "system" },
        { "name": "KONG_KONNECT_MODE", "value": "on" },
        { "name": "KONG_CLUSTER_DP_LABELS", "value": "created-by:quickstart,type:docker-linuxdockerOS" },
        { "name": "KONG_ROUTER_FLAVOR", "value": "expressions" }
      ],
      "portMappings": [
        { "containerPort": 8000, "hostPort": 8000, "protocol": "tcp", "appProtocol": "http" },
        { "containerPort": 8443, "hostPort": 8443, "protocol": "tcp", "appProtocol": "http" }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/kong-data-plane",
          "awslogs-region": "ap-northeast-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ],
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::xxxxxxxxxxxx:role/ecsTaskExecutionRole"
}
```

参考 `docker run` 命令，需修改如下 Kong 相关参数：

- `KONG_CLUSTER_CONTROL_PLANE`
- `KONG_CLUSTER_SERVER_NAME`
- `KONG_CLUSTER_TELEMETRY_ENDPOINT`
- `KONG_CLUSTER_TELEMETRY_SERVER_NAME`
- `KONG_CLUSTER_CERT`
- `KONG_CLUSTER_CERT_KEY`

AWS 相关参数需按实际情况调整：

- `logConfiguration.options`
- `executionRoleArn`

#### 启动 Service

创建 Cluster 后，创建 Service。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/f2c3ba5a-c860-43f7-9919-785c4b311f1a.png)

Service 创建有几点需注意，其他项按需设置。

- `Service Details` 里的 `Task definition family` 选择刚刚创建的 Task
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/0416d0d0-aa08-47af-9cc7-3ffa41112d68.png)

- `Networking` 里的 `Security group` 需开放 `8000` 和 `8443` 端口
- 需外部访问时，`Public IP` 需开启
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/7156874a-2ef7-416a-9f81-7152ad5fc486.png)

设置完成后，点击页面右下角 Create。

## 验证运行

Service 启动后，可在 Konnect 的 `Data Plane Nodes` 查看 ECS Data Plane。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/fc43b78c-8f29-4b84-b992-6c45272bc3a2.png)

AWS ECS 侧可在 Service 下的 Task 查看分配的 `Public IP`。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/c1450735-db1d-464c-84c0-b3d900e13e43.png)

访问该地址会返回 `no Route matched with those values`，说明 Kong Data Plane 部署成功。

```bash
$ http 43.207.xx.xx:8000
HTTP/1.1 404 Not Found
Connection: keep-alive
Content-Length: 103
Content-Type: application/json; charset=utf-8
Date: Thu, 01 May 2025 14:50:17 GMT
Server: kong/3.10.0.1-enterprise-edition
X-Kong-Request-Id: 108134052a77553f758cf668b90e4c1d
X-Kong-Response-Latency: 0

{
    "message": "no Route matched with those values",
    "request_id": "108134052a77553f758cf668b90e4c1d"
}
```

## 总结

本文介绍了如何在 AWS ECS（Fargate）上运行 Kong Konnect Data Plane，实现**最小化配置的 API Gateway 环境**。

- **轻量省资源**  
  Fargate 最小配置 `CPU: 512` / `Memory: 1024` 即可运行  
  Konnect 模式无需外部数据库
  
- **搭建简单**  
  无需复杂网络或负载均衡配置  
  只需复制并修改 Konnect 生成的 `docker run` 命令到 ECS Task Definition
  
- **SaaS 管理免运维**  
  API 路由和安全统一在 Konnect（SaaS）管理  
  Data Plane 只需作为反向代理运行

Kong Konnect 搭配 AWS Fargate，适合想快速体验 API Gateway 的用户。无需配置数据库和负载均衡，SaaS 管理和托管运行环境让你以最小成本轻松上手，简单易扩展，灵活可伸缩。

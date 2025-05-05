---
title: "Building an API Gateway Environment with Konnect + AWS ECS"
date: 2025-05-01T23:49:19+09:00
draft: false
tags:
- kong
- Konnect
- ECS
---

This article introduces how to deploy microservices using AWS ECS (Elastic Container Service) Fargate as the Data Plane for [Kong Konnect](https://konghq.com/kong-konnect/) and build an API Gateway environment.

## Prerequisites

- AWS account
- Kong Konnect account

## Setup Steps

### On the Kong Konnect Side

Log in to [Konnect](https://cloud.konghq.com/us/overview/), go to `Gateway manager` -> `Data Plane Nodes` -> `Configure data plane`, and click `Generate Certificate` to generate a docker run command. Copy the parameters from this command, as you will use them later.

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/c869a45c-04df-4f70-ac9e-8c23757429d0.png)

Once the certificate is generated, the work on the Konnect side is done. The certificate and key contain line breaks, so to set them as ECS environment variables, use the following command to convert them to a single line:

```bash
awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' tls.key
```

### On the AWS ECS Side

#### Container Definition

Go to `AWS ECS` -> `Task definitions` -> `Create new task definition with JSON` to define the container.

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/6dd7ead4-3cf4-47b1-8e31-f8a15ca0891a.png)

Use the following JSON:

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
        {
          "name": "KONG_ROLE",
          "value": "data_plane"
        },
        {
          "name": "KONG_DATABASE",
          "value": "off"
        },
        {
          "name": "KONG_VITALS",
          "value": "off"
        },
        {
          "name": "KONG_CLUSTER_MTLS",
          "value": "pki"
        },
        {
          "name": "KONG_CLUSTER_CONTROL_PLANE",
          "value": "xxxxxxxxxxxx.us.cp0.konghq.com:443"
        },
        {
          "name": "KONG_CLUSTER_SERVER_NAME",
          "value": "xxxxxxxxxxxx.us.cp0.konghq.com"
        },
        {
          "name": "KONG_CLUSTER_TELEMETRY_ENDPOINT",
          "value": "xxxxxxxxxxxx.us.tp0.konghq.com:443"
        },
        {
          "name": "KONG_CLUSTER_TELEMETRY_SERVER_NAME",
          "value": "xxxxxxxxxxxx.us.tp0.konghq.com"
        },
        {
          "name": "KONG_CLUSTER_CERT",
          "value": "<CERT in one line>"
        },
        {
          "name": "KONG_CLUSTER_CERT_KEY",
          "value": "<CERT key in one line>"
        },
        {
          "name": "KONG_LUA_SSL_TRUSTED_CERTIFICATE",
          "value": "system"
        },
        {
          "name": "KONG_KONNECT_MODE",
          "value": "on"
        },
        {
          "name": "KONG_CLUSTER_DP_LABELS",
          "value": "created-by:quickstart,type:docker-linuxdockerOS"
        },
        {
          "name": "KONG_ROUTER_FLAVOR",
          "value": "expressions"
        }
      ],
      "portMappings": [
        {
          "containerPort": 8000,
          "hostPort": 8000,
          "protocol": "tcp",
          "appProtocol": "http"
        },
        {
          "containerPort": 8443,
          "hostPort": 8443,
          "protocol": "tcp",
          "appProtocol": "http"
        }
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

Based on the `docker run` command, you need to update the following Kong parameters:

- `KONG_CLUSTER_CONTROL_PLANE`
- `KONG_CLUSTER_SERVER_NAME`
- `KONG_CLUSTER_TELEMETRY_ENDPOINT`
- `KONG_CLUSTER_TELEMETRY_SERVER_NAME`
- `KONG_CLUSTER_CERT`
- `KONG_CLUSTER_CERT_KEY`

You should also update the following parameters to match your AWS settings:

- `logConfiguration.options`
- `executionRoleArn`

#### Start the Service

After creating the cluster, create a Service.

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/f2c3ba5a-c860-43f7-9919-785c4b311f1a.png)

There are a few key points when creating the Service. Set the other options as appropriate.

- In `Service Details`, select the Task you just created for `Task definition family`.
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/0416d0d0-aa08-47af-9cc7-3ffa41112d68.png)

- In `Networking`, for `Security group`, you need to open ports `8000` and `8443`.
- Since you need external access, turn on `Public IP`.
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/7156874a-2ef7-416a-9f81-7152ad5fc486.png)

Once everything is set, click Create at the bottom right of the page.

## Operation Check

Once the Service is running, you can check the ECS Data Plane in Konnect's `Data Plane Nodes`.

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/fc43b78c-8f29-4b84-b992-6c45272bc3a2.png)

On the AWS ECS side, you can check the assigned `Public IP` address under the Task in the Service.

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/c1450735-db1d-464c-84c0-b3d900e13e43.png)

If you access the address, you should get a `no Route matched with those values` response, confirming that the Kong Data Plane has been successfully set up.

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

## Summary

This article introduced how to **build an API Gateway environment with the minimum configuration** by running Kong Konnect's Data Plane on AWS ECS (Fargate).

- **Lightweight and Resource-Efficient**  
  Fargate can run with the minimum configuration of `CPU: 512` / `Memory: 1024`  
  No external DB required for Konnect
  
- **Easy Setup**  
  No need for complex network or load balancer configuration.  
  Just copy and modify the ECS Task Definition based on the `docker run` command issued by Konnect
  
- **No Management Required with SaaS Integration**  
  Manage API routing and security centrally on Konnect (SaaS).  
  The data plane just needs to run as a simple reverse proxy

The combination of Kong Konnect and AWS Fargate is ideal for those who want to try an API Gateway without the hassle of infrastructure setup. No need to configure databases or load balancers, and with SaaS management and a managed runtime, you can get started easily with minimal setup. It's simple to introduce and offers a flexible configuration that can scale as needed.

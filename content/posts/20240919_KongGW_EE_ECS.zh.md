---
title: "在 AWS ECS Fargate 环境部署 Kong Gateway"
date: 2024-09-19T23:49:19+09:00
draft: false
tags:
- Kong Gateway
- ECS
---

## AWS Elastic Container Service (ECS) 概述

AWS 的 Elastic Container Service (ECS) 是一项全托管的容器编排服务，可以轻松运行、停止和管理容器化应用。ECS 具有以下主要特点：

- 利用 AWS 基础设施实现高可用性和可扩展性
- 支持 Docker 容器
- 与其他 AWS 服务集成
- 灵活的调度选项

Kong Gateway 是高性能的开源 API 网关，提供微服务管理、安全、监控等多种功能。本文介绍如何在 ECS 环境中安装 Kong Gateway。整体安装流程如下图所示：

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/c36a06a9-fba4-f919-e857-860cdff476bb.png)

## 数据库准备

本次部署使用与 PostgreSQL 兼容的 Aurora DB。创建 Aurora DB 时可以指定数据库名，建议一开始就为 Kong 指定好。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/82af62be-cad8-3159-7d4c-64066fb8024a.png)

## ecs-cli 命令准备

接下来准备命令。可以预先定义访问权限和集群信息。由于本次创建的是 FARGATE 类型，需将 default-launch-type 设为 FARGATE。

```bash
> ecs-cli configure profile \
     --profile-name kong-profile \
     --access-key xxxxxxxx \
     --secret-key xxxxxxxx
INFO[0000] Saved ECS CLI profile configuration kong-profile.

> ecs-cli configure \
    --cluster kong-ecs \
    --region ap-northeast-1 \
    --config-name kong-config \
    --default-launch-type FARGATE
INFO[0000] Saved ECS CLI cluster configuration kong-config.
```

这些设置内容可在 `.ecs` 目录下的文件中查看。

```bash
> cat .ecs/config
version: v1
default: kong-config
clusters:
  kong-config:
    cluster: kong-ecs-demo
    region: ap-northeast-1
    default_launch_type: FARGATE
    
> cat .ecs/credentials
version: v1
default: kong-profile
ecs_profiles:
  kong-profile:
    aws_access_key_id: xxxxxxxxxxxx
    aws_secret_access_key: xxxxxxxxxxx
```

## 创建 ECS 集群

基于上述设置，使用 ecs-cli 创建 ECS 集群。VPC、子网等所需资源会自动生成。

```bash
> ecs-cli up --capability-iam --cluster-config kong-config
INFO[0000] Created cluster                               cluster=kong-ecs-demo region=ap-northeast-1
INFO[0000] Waiting for your cluster resources to be created...
INFO[0001] Cloudformation stack status                   stackStatus=CREATE_IN_PROGRESS
VPC created: vpc-0c8bd4ff24a588273
Subnet created: subnet-08a35c8103b05b6a6
Subnet created: subnet-0211846377e4c3d29
Cluster creation succeeded.
```

如需使用已有 VPC 或子网，可通过 `--vpc` 和 `--subnets` 参数指定。

```bash
> ecs-cli up --vpc vpc-xxxxxxxxxxx \
             --subnets subnet-xxxxxxxxxxx,subnet-xxxxxxxxxxx,subnet-xxxxxxxxxxx\
             --cluster-config kong-config \
             --ecs-profile kong-profile
```

VPC 确定后，接着确认安全组 ID。

```bash
aws ec2 describe-security-groups \
        --filters Name=vpc-id,Values=vpc-xxxxxxxxxx | grep -i GroupId
                            "GroupId": "sg-yyyyyyyyyy",
            "GroupId": "sg-yyyyyyyyyy",
```

ECS 集群创建完成后，建议记录以下资源 ID：

- 使用的 VPC
- 子网
- 安全组

## 准备任务和服务定义文件

ECS 的任务和服务配置在如下文件中定义。注意事项如下：

- ecs_network_mode 只能设置为 awsvpc
- task_execution_role 需正确设置

```YAML
version: 1
task_definition:
  ecs_network_mode: awsvpc
  task_size:
    cpu_limit: 256
    mem_limit: 1024
  task_execution_role: arn:aws:iam::xxxxxxxxxxxx:role/ecsTaskExecutionRole
  services:
    kong-migrations:
      essential: false
      logConfiguration :
        logDriver: awslogs
        options:
          awslogs-group: kong
          awslogs-region: ap-northeast-1
          awslogs-stream-prefix: log-kong
    kong:
      hostname: kong
      essential: true
      depends_on:
      - container_name: kong-migrations
        condition: COMPLETE
      logConfiguration :
        logDriver: awslogs
        options:
          awslogs-group: kong
          awslogs-region: ap-northeast-1
          awslogs-stream-prefix: log-kong
run_params:
   network_configuration:
     awsvpc_configuration:
       subnets:
         - "subnet-08a35c8103b05b6a6"
         - "subnet-0211846377e4c3d29"
       security_groups:
         - "sg-025b2859c18d70c2c"
       assign_public_ip: ENABLED
```

## 准备服务中容器定义文件

定义 Kong Gateway 容器的启动条件。各参数细节略，`KONG_ADMIN_GUI_URL` 和 `KONG_ADMIN_GUI_API_URL` 需按实际环境设置。

```YAML
version: "3"
services:
  kong-migrations:
    image: kong/kong-gateway:3.4.3.12
    command: kong migrations bootstrap
    environment:
      - KONG_DATABASE=postgres
      - KONG_PG_HOST=wenhan.cluster-cad2bwtkwmrs.ap-northeast-1.rds.amazonaws.com
      - KONG_PG_USER=wenhan
      - KONG_PG_PASSWORD=kongkong
      - KONG_PASSWORD=kong
    logging:
      driver: awslogs
      options:
        awslogs-group: kong
        awslogs-region: ap-northeast-1
        awslogs-stream-prefix: log-kong-init
  kong:
    image: kong/kong-gateway:3.4.3.12
    ports:
      - 8000:8000
      - 8001:8001
      - 8002:8002
      - 8443:8443
      - 8444:8444
      - 8445:8445
    command: "kong start"
    environment:
      - KONG_ADMIN_GUI_URL=http://wenhan-manager.service-connectivity.com:8002
      - KONG_ADMIN_GUI_API_URL=http://wenhan-admin.service-connectivity.com:8001
      - KONG_DATABASE=postgres
      - KONG_PG_HOST=wenhan.cluster-cad2bwtkwmrs.ap-northeast-1.rds.amazonaws.com
      - KONG_PG_USER=wenhan
      - KONG_PG_PASSWORD=kongkong
      - KONG_PROXY_ACCESS_LOG=/dev/stdout
      - KONG_ADMIN_ACCESS_LOG=/dev/stdout
      - KONG_PROXY_ERROR_LOG=/dev/stderr
      - KONG_ADMIN_ERROR_LOG=/dev/stderr
      - KONG_PROXY_LISTEN=0.0.0.0:8000, 0.0.0.0:8443 ssl
      - KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl
      - KONG_ADMIN_GUI_LISTEN=0.0.0.0:8002, 0.0.0.0:8445 ssl
      - KONG_LOG_LEVEL=info
    logging:
      driver: awslogs
      options:
        awslogs-group: kong
        awslogs-region: ap-northeast-1
        awslogs-stream-prefix: log-kong
```

## 启动任务和服务

使用 compose up 命令启动任务和服务，相关参数指定上述文件。

```bash
ecs-cli compose \
 --file docker-compose.yml \
 --ecs-params ./ecs-params.yml \
 --debug service up \
 --create-log-groups
```

这样会启动两个容器。`migrations` 容器用于初始化数据库，处理完成后会变为 `Stopped` 状态。另一个是正在运行的 Kong Gateway 服务。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/a66537f8-b299-1af8-ad0d-55ea30f76a29.png)

在任务的 `Networking` 中会分配外部 IP 地址，可通过该地址访问 Kong 服务。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/6daefe66-83f9-4625-43d6-ff77f15b6437.png)

例如可通过 `http://<IP address>:8001` 访问 Admin API。

## 停止任务和服务

```bash
ecs-cli compose \
 --file docker-compose.yml \
 --ecs-params ./ecs-params.yml \
 --debug service down
```

## 后记

剩余工作：

- 创建指向该 IP 的 Target Group 并创建 ALB
- 在 Route 53 创建 DNS 记录

实际上，上述操作也可以通过 Terraform 或 CloudFormation 进一步自动化，TBD。

---
title: "使用 Docker Compose 快速启动 SonarQube"
date: 2025-09-22T23:49:19+09:00
draft: false
tags:
- Sonar
- SonarQube
---

[Qiita 原文](https://qiita.com/xibuka/items/24bf8a9441725894dd2a)介绍了两种使用 Docker Compose 启动 SonarQube 的方式：使用内置数据库进行试用，以及使用 PostgreSQL 的部署方式。

## 准备工作

请先安装 Docker 和 Docker Compose。

## 使用内置数据库进行试用

SonarQube 内置用于评估的 H2 数据库，因此无需额外启动数据库容器。若没有配置数据持久化，删除容器时数据也会丢失，所以这种方式适合试用。

创建 `compose.yml`：

```yaml
version: "3"

services:
  sonarqube:
    image: sonarqube:latest
    container_name: sonarqube
    ports:
      - "9000:9000"
    environment:
      - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
    volumes:
      - ./sq-logs:/opt/sonarqube/logs
      - ./sq-data:/opt/sonarqube/data
      - ./sq-extensions:/opt/sonarqube/extensions
```

在该目录中启动服务：

```bash
docker-compose up -d
```

访问 `http://localhost:9000`，确认登录页面正常显示。初始用户名和密码为 `admin` / `admin`。登录后请修改密码。

![SonarQube 登录页面](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/c252b55a-038c-4a91-9978-53a5ab128ea3.png)

## 使用 PostgreSQL

面向正式使用时，可以让 SonarQube 和 PostgreSQL 分别运行在独立容器中：

```yaml
services:
  sonarqube:
    image: sonarqube:latest
    ports:
      - "9000:9000"
    environment:
      SONAR_JDBC_USERNAME: sonarqube_user
      SONAR_JDBC_PASSWORD: sonarqube_pw
      SONAR_JDBC_URL: jdbc:postgresql://postgres-db:5432/sonarqube_db
      SONAR_TELEMETRY_ENABLE: "false"
    volumes:
      - ./sq-logs:/opt/sonarqube/logs
      - ./sq-data:/opt/sonarqube/data
      - ./sq-extensions:/opt/sonarqube/extensions

  postgres-db:
    image: postgres:17
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: sonarqube_user
      POSTGRES_PASSWORD: sonarqube_pw
      POSTGRES_DB: sonarqube_db
    volumes:
      - ./pg-data:/var/lib/postgresql/data
```

SonarQube 的 JDBC 用户名、密码和 URL 必须与 PostgreSQL 配置一致。Docker Compose 网络支持通过服务名进行容器间通信。为两个服务配置 volume，以持久保存数据。

```bash
docker-compose up -d
```

然后访问 `http://localhost:9000`，等待 SonarQube 连接 PostgreSQL 并完成初始化。

## 总结

内置数据库适合快速试用，PostgreSQL 适合需要持久化数据的部署。用于实际运行时，应固定镜像版本并妥善管理数据库凭据。

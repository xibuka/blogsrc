---
title: "结合 HashiCorp Vault 部署 Kong Gateway"
date: 2023-02-23T00:34:38+09:00
draft: false
tags:
- Kong Gateway
- Vault
- Secrets Management
---

## 背景

从 Kong Gateway 3.0 开始，Secrets Management（密钥管理）已正式 GA。Kong Gateway 运行时依赖许多密钥，从数据库密码到插件用的 API Key。过去可以用 RBAC 限制 Admin API 和 Kong Manager 对敏感信息的访问，但如果能让密钥不以明文显示进行管理就更好了，这正是 Secrets Management 能实现的。

## 支持的 Vault

目前支持以下四种 Vault：

- AWS Secrets Manager
- GCP Secrets Manager
- HashiCorp Vault
- 环境变量

Kong 对上述系统做了抽象，实际使用时只需切换 Vault 关键字（hcv、aws、gcp 或 env）即可。例如，要访问 HashiCorp Vault 中 Postgres Secret 的 password 字段，可以这样引用：

`{vault://hcv/postgres/password}`

AWS Secrets Manager 的情况：

`{vault://aws/postgres/password}`

环境变量的情况：

```conf
    export POSTGRES='{"username":"user", "password":"pass"}'
    {vault://env/postgres/password}
```

## 演示

下面实际用 Secrets Management 参照 Vault 的密钥并部署 Kong。

### 准备 Vault 环境

这里将 TOKEN_ID 设为 kong。该值后续认证时会用到。

```bash
docker run -d --name vault.idp \
  --network=kong-net \
  -e "VAULT_DEV_ROOT_TOKEN_ID=kong" \
  -p 8200:8200 \
  --cap-add=IPC_LOCK \
  vault:latest
```

### 创建 Secret

进入容器并创建密钥。

```bash
    docker exec -it vault.idp sh
    / ## export VAULT_ADDR='http://127.0.0.1:8200'
    / ## export VAULT_TOKEN="kong"
    / ## vault kv put -mount secret kong pg_password=kongpass
```

如果不设置 VAULT_ADDR 和 VAULT_TOKEN，会报错：`Get "https://127.0.0.1:8200/v1/sys/internal/ui/mounts/secret": http: server gave HTTP response to HTTPS client`。

### 利用 Secret 部署 Kong Gateway

Vault 启动后，启动 Kong Gateway 的 Docker 容器。数据库连接参数 `KONG_PG_PASSWORD` 处，改为引用 HashiCorp Vault 的密钥 `{vault://hcv/kong/pg_password}`。Vault 的连接信息通过 `KONG_VAULT_HCV_*` 参数配置。

```bash
docker run -d --name kong-gateway-sm \
  --network=kong-net \
  -e "KONG_DATABASE=postgres" \
  -e "KONG_PG_HOST=kong-database" \
  -e "KONG_PG_USER=kong" \
  -e "KONG_PG_PASSWORD={vault://hcv/kong/pg_password}" \
  -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
  -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
  -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
  -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
  -e "KONG_ADMIN_LISTEN=0.0.0.0:8001" \
  -e "KONG_ADMIN_GUI_URL=http://localhost:8002" \
  -e "KONG_VAULT_HCV_PROTOCOL=http" \
  -e "KONG_VAULT_HCV_HOST=vault.idp" \
  -e "KONG_VAULT_HCV_PORT=8200" \
  -e "KONG_VAULT_HCV_MOUNT=secret" \
  -e "KONG_VAULT_HCV_KV=v2" \
  -e "KONG_VAULT_HCV_AUTH_METHOD=token" \
  -e "KONG_VAULT_HCV_TOKEN=kong" \
  -e KONG_LICENSE_DATA \
  -p 8000:8000 \
  -p 8443:8443 \
  -p 8001:8001 \
  -p 8444:8444 \
  -p 8002:8002 \
  -p 8445:8445 \
  -p 8003:8003 \
  -p 8004:8004 \
  kong/kong-gateway:3.1.1.3
```

容器能正常启动就说明已成功从 Vault 读取密钥！

### 利用 Secret 部署插件

由于已配置 Vault 访问信息，部署插件时也能引用密钥。如下例，部署 `Proxy Caching Advanced` 插件时，`config.redis.password` 配置引用了 Vault。

```bash
curl localhost:8001/services/example-service/plugins \
--data "name=proxy-cache-advanced"  \
--data "config.response_code=200" \
--data "config.request_method=GET" \
--data "config.content_type=application/json; charset=utf-8" \
--data "config.cache_control=false" \
--data "config.strategy=redis" \
--data "config.redis.host=host.docker.internal" \
--data "config.redis.port=6379" \
--data "config.redis.password={vault://hcv/redis/password}"
```

以上！本文介绍了如何在 Kong GW 中管理和引用密钥。目前环境变量、HashiCorp Vault、AWS Secrets Manager、GCP Secrets Manager 的驱动已内置，可直接使用。Azure Key Vault 的支持也即将上线，敬请期待！

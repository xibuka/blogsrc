---
title: "Deploy Kong Gateway Referencing HashiCorp Vault"
date: 2023-02-23T00:34:38+09:00
draft: false
tags:
- Kong Gateway
- Vault
- Secrets Management
---

## Background

From Kong Gateway 3.0, Secrets Management has become GA. Kong Gateway relies on many secrets, from database passwords to API keys used in plugins. Previously, you could use RBAC to restrict access to sensitive information from the Admin API and Kong Manager, but it would be great if you could manage secrets without displaying them in plain text. This is made possible by Secrets Management.

## Supported Vaults

Currently, the following four types of Vaults are supported:

- AWS Secrets Manager
- GCP Secrets Manager
- HashiCorp Vault
- Environment Variable

Kong abstracts each of the above systems, so you can use them by simply changing the Vault keyword (hcv, aws, gcp, or env) when referencing. For example, to access the password field of a Postgres Secret in HashiCorp Vault, you can refer to it in the following format:

`{vault://hcv/postgres/password}`

For AWS Secrets Manager:

`{vault://aws/postgres/password}`

For environment variables:

```conf
    export POSTGRES='{"username":"user", "password":"pass"}'
    {vault://env/postgres/password}
```

## Demo

Let's actually use Secrets Management to reference Vault secrets and try deploying Kong.

### Prepare the Vault Environment

Here, set TOKEN_ID to kong. This value will be used later for authentication.

```bash
docker run -d --name vault.idp \
  --network=kong-net \
  -e "VAULT_DEV_ROOT_TOKEN_ID=kong" \
  -p 8200:8200 \
  --cap-add=IPC_LOCK \
  vault:latest
```

### Create a Secret

Enter the container and create a secret.

```bash
    docker exec -it vault.idp sh
    / ## export VAULT_ADDR='http://127.0.0.1:8200'
    / ## export VAULT_TOKEN="kong"
    / ## vault kv put -mount secret kong pg_password=kongpass
```

If you do not set VAULT_ADDR and VAULT_TOKEN, you will get the error: `Get "https://127.0.0.1:8200/v1/sys/internal/ui/mounts/secret": http: server gave HTTP response to HTTPS client`.

### Deploy Kong Gateway Using the Secret

Once Vault is up and running, start the Kong Gateway Docker container. For the DB connection parameter `KONG_PG_PASSWORD`, change it to reference the secret from HashiCorp Vault as `{vault://hcv/kong/pg_password}`. The connection information to Vault is set with the `KONG_VAULT_HCV_*` parameters.

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

If the container starts successfully, you have successfully referenced the secret from Vault!

### Deploy a Plugin Using the Secret

Since the Vault access information is set, you can also reference secrets when deploying plugins. In the following example, when deploying the `Proxy Caching Advanced` plugin, the `config.redis.password` setting is referenced from Vault.

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

That's it! We've introduced how to manage and reference secrets with Kong GW. Currently, drivers for environment variables, HashiCorp Vault, AWS Secrets Manager, and GCP Secrets Manager are built-in and ready to use. Good news for Azure Key Vault fans: support will be added soon, so please stay tuned!

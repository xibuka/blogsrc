---
title: "HashiCorp Vaultを参照しKongGatewayをデプロイ"
date: 2023-02-23T00:34:38+09:00
draft: false
tags:
- Kong Gateway
- Vault
- Secrets Management
---

# 背景
Kong Gateway 3.0 から、Secrets ManagementがGAとなりました。Kong Gateway は、データベースのパスワードからプラグインで使用される API キーまで、多くのSecretに依存して動作します。以前ではRBACを使って、Admin APIとKong Managerから機密情報へのアクセスを制限できましたが、Secretを平文で表示されずに管理できたら嬉しいですよね。これを実現できるのはSecrets Managementです。

# サポートするVault
現時点で、サポートしているVaultは以下の４種類です。
- AWS Secrets Manager
- GCP Secrets Manager
- HashiCorp Vault
- Environment Variable

Kong は、上記の各システムを抽象化して、利用するときにVaultのキーワード(hcv、aws、gcpまたは env)を変更するだけで利用できます。たとえば、HashiCorp Vaultの Postgres Secretのpassword フィールドにアクセスするには、次のフォーマットで参照できます。

    {vault://hcv/postgres/password}

AWS Secrets Managerの場合

    {vault://aws/postgres/password}

環境変数の場合

    export POSTGRES='{"username":"user", "password":"pass"}'
    {vault://env/postgres/password}

# デモ
では実際にSecrets Managementを使ってVaultのSecretsを参照し、Kongのデプロイを試してみよう

## Vault環境を用意
ここで、TOKEN_IDをkongにします。この値は後の認証するときに使用されます。
```
docker run -d --name vault.idp \
  --network=kong-net \
  -e "VAULT_DEV_ROOT_TOKEN_ID=kong" \
  -p 8200:8200 \
  --cap-add=IPC_LOCK \
  vault:latest
```

## Secretを作成

コンテナーに入って、Secretを作成しましょう

    docker exec -it vault.idp sh
    / # export VAULT_ADDR='http://127.0.0.1:8200'
    / # export VAULT_TOKEN="kong"
    / # vault kv put -mount secret kong pg_password=kongpass

VAULT_ADDRとVAULT_TOKENを設定しないと、`Get "https://127.0.0.1:8200/v1/sys/internal/ui/mounts/secret": http: server gave HTTP response to HTTPS client`のエラーが出ます。

## Secretを利用しKong gatewayをデプロイ

Vaultが無事起動している状態でしたら、Kong GatewayのDocker コンテナーも起動しに行きます。DBへの接続用のパラメータ`KONG_PG_PASSWORD`のところに、HashiCorp VaultからSecretを参照するように`{vault://hcv/kong/pg_password}`と書き換えています。Vaultへの接続情報は`KONG_VAULT_HCV_*`のパラメータで設定しています。

```
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

コンテナーが無事起動しているであれば、ちゃんとVaultからSecretが参照できましたね！

## Secretを利用しプラグインをデプロイ

Vaultへのアクセス情報を設定しているため、PluginをデプロイするときにもSecretを参照することができます。以下の例では、`Proxy Caching Advanced`プラグインをデプロイするときに、`config.redis.password`の設定はVaultからの参照にしています。

```
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

以上！Kong GWで機密情報の管理や参照の方法をご紹介しました。現時点では、環境変数、HashiCorp Vault、 AWS Secrets Manager、およびGCP Secrets Managerのドライバはbuilt-inで入っているのですぐ利用できます。Azure Key Vaultファンの方には朗報です。近いうちにそちらもサポートするようになるのでもう少しお待ちください！


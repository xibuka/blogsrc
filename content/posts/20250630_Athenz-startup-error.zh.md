---
title: "启动 Athenz 时遇到的错误及解决方法"
date: 2025-06-30T23:49:19+09:00
draft: false
tags:
- Athenz
- RBAC
- IdP
---

Athenz 是由 Yahoo 开发的开源认证与授权框架，面向微服务环境设计。它通过 X.509 证书认证服务间通信，并通过 RBAC（基于角色的访问控制）提供细粒度的权限控制，常用于 Kubernetes 和云环境中的零信任安全架构。

本文记录启动 Athenz 时遇到的问题及解决方法。

## 使用 Docker 启动时的问题

为了快速了解功能和 UI，我们先使用 Docker 启动。Athenz 已经提供了启动脚本。

运行脚本后，流程在启动 ZTS 时遇到以下错误，无法继续：

```text
...
4. start ZTS
834a8538a18b6944fd0f55e3316a3588301c75a6891e6e7538df2227c1d37fdd
curl: (7) Failed to connect to athenz-zts-server port 8443: Connection refused
ZTS is unavailable - will sleep 3s...
curl: (22) The requested URL returned error: 503 Service Unavailable
ZTS is unavailable - will sleep 3s...
curl: (22) The requested URL returned error: 503 Service Unavailable
ZTS is unavailable - will sleep 3s...
...
```

## 故障排查

检查容器状态后发现，ZTS 容器处于 `unhealthy` 状态，状态接口也返回 `503`。

```bash
docker ps -a | grep -i zts
834a8538a18b   athenz/athenz-zts-server:latest   "/usr/local/bin/dock…"   4 minutes ago   Up 4 minutes (unhealthy)   0.0.0.0:8443->8443/tcp, [::]:8443->8443/tcp   athenz-zts-server
3a524f4f3fc6   athenz/athenz-zts-db:latest       "docker-entrypoint.s…"   4 minutes ago   Up 4 minutes (healthy)     0.0.0.0:3307->3306/tcp, [::]:3307->3306/tcp   athenz-zts-db

curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8443/zts/v1/status
503
```

查看 `server.log` 后发现，ZMS 服务器启动时因为没有配置 OAuth 的 JWKS（JSON Web Key Set）URI，导致初始化失败。

```text
ERROR c.y.a.a.o.OAuthCertBoundJwtAccessTokenAuthority - Invalid OAuthJwtAccessTokenParserFactory class: com.yahoo.athenz.auth.oauth.parser.DefaultOAuthJwtAccessTokenParserFactory
...
Caused by: com.yahoo.athenz.auth.util.CryptoException: Jwks uri must be specified
```

检查配置后发现，`athenz.zms.authority_classes` 中包含了 `com.yahoo.athenz.auth.oauth.OAuthCertBoundJwtAccessTokenAuthority`。

```bash
docker exec athenz-zms-server cat /opt/athenz/zms/conf/zms_server/zms.properties

athenz.zms.authority_classes=com.yahoo.athenz.auth.impl.PrincipalAuthority,com.yahoo.athenz.auth.impl.TestUserAuthority,com.yahoo.athenz.auth.oauth.OAuthCertBoundJwtAccessTokenAuthority,com.yahoo.athenz.auth.impl.CertificateAuthority
```

OAuth Authority 必须配置 JWKS URI。本例只使用 ZMS 的基础功能（例如基于 X.509 的认证），因此从配置中移除 OAuth Authority 即可解决问题。

```bash
docker exec athenz-zms-server sed -i 's/athenz.zms.authority_classes=com.yahoo.athenz.auth.impl.PrincipalAuthority,com.yahoo.athenz.auth.impl.TestUserAuthority,com.yahoo.athenz.auth.oauth.OAuthCertBoundJwtAccessTokenAuthority,com.yahoo.athenz.auth.impl.CertificateAuthority/athenz.zms.authority_classes=com.yahoo.athenz.auth.impl.PrincipalAuthority,com.yahoo.athenz.auth.impl.TestUserAuthority,com.yahoo.athenz.auth.impl.CertificateAuthority/' /opt/athenz/zms/conf/zms_server/zms.properties

docker exec athenz-zts-server sed -i 's/athenz.zts.authority_classes=com.yahoo.athenz.auth.oauth.OAuthCertBoundJwtAccessTokenAuthority,com.yahoo.athenz.auth.impl.CertificateAuthority/athenz.zts.authority_classes=com.yahoo.athenz.auth.impl.CertificateAuthority/' /opt/athenz/zts/conf/zts_server/zts.properties
```

重启容器以应用新配置。重启后，ZMS 状态变为 `healthy`，状态接口也返回 `200`。

```bash
docker restart athenz-zms-server

docker ps -a | grep zms
0b455c9d1508   athenz/athenz-zms-server:latest   "/usr/local/bin/dock…"   5 minutes ago   Up 15 seconds (healthy)   0.0.0.0:4443->4443/tcp, [::]:4443->4443/tcp   athenz-zms-server
fe60903808f3   athenz/athenz-zms-db:latest       "docker-entrypoint.s…"   5 minutes ago   Up 5 minutes (healthy)   0.0.0.0:3306->3306/tcp, [::]:3306->3306/tcp   athenz-zms-db

curl -k -s https://localhost:4443/zms/v1/status
{"code":200,"message":"OK"}
```

## 确认结果

之后部署顺利完成，也可以正常登录 UI。

```text
#################################################
### Athenz is up!
#################################################

You can access UI now at https://localhost
```

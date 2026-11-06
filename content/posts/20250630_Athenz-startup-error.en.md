---
title: "Troubleshooting an Athenz Startup Error"
date: 2025-06-30T23:49:19+09:00
draft: false
tags:
- Athenz
- RBAC
- IdP
---

Athenz is an open-source authentication and authorization framework developed by Yahoo for microservice environments. It uses X.509 certificates to authenticate service-to-service communication and provides fine-grained access control through RBAC (Role-Based Access Control). It is commonly used as a foundation for zero-trust security in Kubernetes and cloud environments.

This article describes an error encountered while starting Athenz and how to resolve it.

## Problem when starting with Docker

To quickly explore the features and UI, we start Athenz with Docker. A startup script is provided for this purpose.

After running the script, startup stopped at the ZTS step with the following errors:

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

## Troubleshooting

Checking the container status showed that the ZTS container was `unhealthy`, and its status endpoint returned `503`.

```bash
docker ps -a | grep -i zts
834a8538a18b   athenz/athenz-zts-server:latest   "/usr/local/bin/dock…"   4 minutes ago   Up 4 minutes (unhealthy)   0.0.0.0:8443->8443/tcp, [::]:8443->8443/tcp   athenz-zts-server
3a524f4f3fc6   athenz/athenz-zts-db:latest       "docker-entrypoint.s…"   4 minutes ago   Up 4 minutes (healthy)     0.0.0.0:3307->3306/tcp, [::]:3307->3306/tcp   athenz-zts-db

curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8443/zts/v1/status
503
```

The `server.log` showed that the ZMS server failed to initialize because the OAuth JWKS (JSON Web Key Set) URI was not configured.

```text
ERROR c.y.a.a.o.OAuthCertBoundJwtAccessTokenAuthority - Invalid OAuthJwtAccessTokenParserFactory class: com.yahoo.athenz.auth.oauth.parser.DefaultOAuthJwtAccessTokenParserFactory
...
Caused by: com.yahoo.athenz.auth.util.CryptoException: Jwks uri must be specified
```

The configuration contained `com.yahoo.athenz.auth.oauth.OAuthCertBoundJwtAccessTokenAuthority` in `athenz.zms.authority_classes`:

```bash
docker exec athenz-zms-server cat /opt/athenz/zms/conf/zms_server/zms.properties

athenz.zms.authority_classes=com.yahoo.athenz.auth.impl.PrincipalAuthority,com.yahoo.athenz.auth.impl.TestUserAuthority,com.yahoo.athenz.auth.oauth.OAuthCertBoundJwtAccessTokenAuthority,com.yahoo.athenz.auth.impl.CertificateAuthority
```

OAuth Authority requires a JWKS URI. Since this setup only uses the basic ZMS features, such as X.509-based authentication, removing OAuth Authority from the configuration resolves the error.

```bash
docker exec athenz-zms-server sed -i 's/athenz.zms.authority_classes=com.yahoo.athenz.auth.impl.PrincipalAuthority,com.yahoo.athenz.auth.impl.TestUserAuthority,com.yahoo.athenz.auth.oauth.OAuthCertBoundJwtAccessTokenAuthority,com.yahoo.athenz.auth.impl.CertificateAuthority/athenz.zms.authority_classes=com.yahoo.athenz.auth.impl.PrincipalAuthority,com.yahoo.athenz.auth.impl.TestUserAuthority,com.yahoo.athenz.auth.impl.CertificateAuthority/' /opt/athenz/zms/conf/zms_server/zms.properties

docker exec athenz-zts-server sed -i 's/athenz.zts.authority_classes=com.yahoo.athenz.auth.oauth.OAuthCertBoundJwtAccessTokenAuthority,com.yahoo.athenz.auth.impl.CertificateAuthority/athenz.zts.authority_classes=com.yahoo.athenz.auth.impl.CertificateAuthority/' /opt/athenz/zts/conf/zts_server/zts.properties
```

Restart the container to apply the new configuration. After restarting, ZMS became `healthy`, and its status endpoint returned `200`.

```bash
docker restart athenz-zms-server

docker ps -a | grep zms
0b455c9d1508   athenz/athenz-zms-server:latest   "/usr/local/bin/dock…"   5 minutes ago   Up 15 seconds (healthy)   0.0.0.0:4443->4443/tcp, [::]:4443->4443/tcp   athenz-zms-server
fe60903808f3   athenz/athenz-zms-db:latest       "docker-entrypoint.s…"   5 minutes ago   Up 5 minutes (healthy)   0.0.0.0:3306->3306/tcp, [::]:3306->3306/tcp   athenz-zms-db

curl -k -s https://localhost:4443/zms/v1/status
{"code":200,"message":"OK"}
```

## Verify the result

The deployment then completed successfully, and logging in to the UI worked as expected.

```text
#################################################
### Athenz is up!
#################################################

You can access UI now at https://localhost
```

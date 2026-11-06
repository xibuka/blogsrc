---
title: "Athenzを起動する時のエラー"
date: 2025-06-30T23:49:19+09:00
draft: false
tags:
- Athenz
- RBAC
- IdP
---

Athenz は Yahoo が開発したオープンソースの認証・認可フレームワークで、マイクロサービス環境向けに設計されています。サービス間通信のための X.509 証明書による認証と、RBAC（ロールベースアクセス制御）による細粒度のアクセス制御を提供します。特に Kubernetes やクラウド環境において、ゼロトラストセキュリティを実現する基盤として活用できます。

ここでは、Athenz の起動時に遭遇したエラーと、その解決方法を紹介します。

## Dockerで起動時の問題

まず機能と UI を簡単に確認するため、Docker を使って起動します。Athenz には起動スクリプトが用意されています。

スクリプトを実行すると、ZTS の起動後に次のエラーが発生し、処理が進まなくなりました。

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

## トラブルシューティング

コンテナーの状態を確認すると、ZTS コンテナーが `unhealthy` で、ステータス確認のレスポンスも `503` でした。

```bash
docker ps -a | grep -i zts
834a8538a18b   athenz/athenz-zts-server:latest   "/usr/local/bin/dock…"   4 minutes ago   Up 4 minutes (unhealthy)   0.0.0.0:8443->8443/tcp, [::]:8443->8443/tcp   athenz-zts-server
3a524f4f3fc6   athenz/athenz-zts-db:latest       "docker-entrypoint.s…"   4 minutes ago   Up 4 minutes (healthy)     0.0.0.0:3307->3306/tcp, [::]:3307->3306/tcp   athenz-zts-db

curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8443/zts/v1/status
503
```

`server.log` を確認したところ、ZMS サーバーが起動時に OAuth の JWKS（JSON Web Key Set）URI を設定できず、初期化に失敗していました。

```text
ERROR c.y.a.a.o.OAuthCertBoundJwtAccessTokenAuthority - Invalid OAuthJwtAccessTokenParserFactory class: com.yahoo.athenz.auth.oauth.parser.DefaultOAuthJwtAccessTokenParserFactory
...
Caused by: com.yahoo.athenz.auth.util.CryptoException: Jwks uri must be specified
```

設定を確認すると、`athenz.zms.authority_classes` に `com.yahoo.athenz.auth.oauth.OAuthCertBoundJwtAccessTokenAuthority` が含まれていました。

```bash
docker exec athenz-zms-server cat /opt/athenz/zms/conf/zms_server/zms.properties

athenz.zms.authority_classes=com.yahoo.athenz.auth.impl.PrincipalAuthority,com.yahoo.athenz.auth.impl.TestUserAuthority,com.yahoo.athenz.auth.oauth.OAuthCertBoundJwtAccessTokenAuthority,com.yahoo.athenz.auth.impl.CertificateAuthority
```

OAuth Authority を使うには JWKS URI の設定が必要です。今回は ZMS の基本機能（X.509 ベースの認証など）のみを使うため、設定から OAuth Authority を削除します。

```bash
docker exec athenz-zms-server sed -i 's/athenz.zms.authority_classes=com.yahoo.athenz.auth.impl.PrincipalAuthority,com.yahoo.athenz.auth.impl.TestUserAuthority,com.yahoo.athenz.auth.oauth.OAuthCertBoundJwtAccessTokenAuthority,com.yahoo.athenz.auth.impl.CertificateAuthority/athenz.zms.authority_classes=com.yahoo.athenz.auth.impl.PrincipalAuthority,com.yahoo.athenz.auth.impl.TestUserAuthority,com.yahoo.athenz.auth.impl.CertificateAuthority/' /opt/athenz/zms/conf/zms_server/zms.properties

docker exec athenz-zts-server sed -i 's/athenz.zts.authority_classes=com.yahoo.athenz.auth.oauth.OAuthCertBoundJwtAccessTokenAuthority,com.yahoo.athenz.auth.impl.CertificateAuthority/athenz.zts.authority_classes=com.yahoo.athenz.auth.impl.CertificateAuthority/' /opt/athenz/zts/conf/zts_server/zts.properties
```

コンテナーを再起動して設定を反映します。再起動後、ZMS は `healthy` になり、ステータス確認も `200` を返しました。

```bash
docker restart athenz-zms-server

docker ps -a | grep zms
0b455c9d1508   athenz/athenz-zms-server:latest   "/usr/local/bin/dock…"   5 minutes ago   Up 15 seconds (healthy)   0.0.0.0:4443->4443/tcp, [::]:4443->4443/tcp   athenz-zms-server
fe60903808f3   athenz/athenz-zms-db:latest       "docker-entrypoint.s…"   5 minutes ago   Up 5 minutes (healthy)   0.0.0.0:3306->3306/tcp, [::]:3306->3306/tcp   athenz-zms-db

curl -k -s https://localhost:4443/zms/v1/status
{"code":200,"message":"OK"}
```

## 結果確認

その後は最後までデプロイでき、UI にも問題なくログインできました。

```text
#################################################
### Athenz is up!
#################################################

You can access UI now at https://localhost
```

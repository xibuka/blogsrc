---
title: "Kong GatewayのAudit Log"
date: 2024-05-01T23:49:19+09:00
draft: false
tags:
- kong
---

## 概要
KongのAudit Logは、Kongが行う各種操作を記録することで、システムの状態やセキュリティに関する洞察を提供します。これにより、システムの変更や問題のトラッキング、セキュリティ侵害の検出などが可能になります。

KongのAudit Logには、一般的にJSON形式で、次のような情報が記録されます。

- リクエストやレスポンスのデータ
- ルートやサービスへのアクセス試行
- ユーザーまたはクライアントの認証情報
- APIキーの使用
- エラーまたは警告メッセージ
- システムイベントや構成変更

https://docs.konghq.com/gateway/latest/kong-enterprise/audit-log/

## 機能の有効化
Kong Audit logは、Enterpriseの機能です。デフォルトではOffであって、`audit_log`の変更で有効無効が設定できます。

```config
audit_log = on ## audit logging is enabled
audit_log = off ## audit logging is disabled
```

## 利用方法

例えば以下のようなアクセスがあった場合

```bash
$ curl -i -X GET http://localhost:8001/status
```

このアクセスはAudit logに記録され、以下のリクエストで取得できます。

```bash
$ curl -i -X GET http://localhost:8001/audit/requests

HTTP/1.1 200 OK
Access-Control-Allow-Origin: *
Connection: keep-alive
Content-Type: application/json; charset=utf-8
Date: Tue, 13 Nov 2018 17:35:24 GMT
Server: kong/3.6.1.3-enterprise-edition
Transfer-Encoding: chunked
X-Kong-Admin-Request-ID: VXgMG1Y3rZKbjrzVYlSdLNPw8asVwhET

{
   "data": [
       {
           "client_ip": "127.0.0.1",
           "method": "GET",
           "path": "/status",
           "payload": null,
           "rbac_user_id": null,
           "rbac_user_name": null,
           "removed_from_payload": null,
           "request_id": "OjOcUBvt6q6XJlX3dd6BSpy1uUkTyctC",
           "request_source": null,
           "request_timestamp": 1676424547,
           "signature": null,
           "status": 200,
           "ttl": 2591997,
           "workspace": "1065b6d6-219f-4002-b3e9-334fc3eff46c"
       }
   ],
   "total": 1
}
```

上記の場合、`rbac_user_id`と`rbac_user_name`は`null`になる理由は、RBACが有効になっていないからです。もしRBACがOnな状態でもう一度アクセスログを確認すると、以下のようにちゃんと`rbac_user_id`と`rbac_user_name`に値がありまして、誰がアクセスしたのかは分かります。

```bash
{
   "data": [
       {
           "client_ip": "127.0.0.1",
           "method": "GET",
           "path": "/status",
           "payload": null,
           "rbac_user_id": "2e959b45-0053-41cc-9c2c-5458d0964331",
           "rbac_user_name": "admin",
           "request_id": "QUtUa3RMbRLxomqcL68ilOjjl68h56xr",
           "request_source": "kong-manager",
           "request_timestamp": 1581617463,
           "signature": null,
           "status": 200,
           "ttl": 2591995,
           "workspace": "0da4afe7-44ad-4e81-a953-5d2923ce68ae"
       }
   ],
   "total": 1
}
```

### ログローテーション
Audit Logは、KongのDBに、`audit_log_record_ttl`で定義して期間内に保存されます。`audit_log_record_ttl`を過ぎたログは自動で削除されます。このパラメータのデフォルトは30日です。

PostgreSQLは、DBにinsertがあるときに、上記の自動削除が行われます。そのため、Audit Logのエントリは上記TTL設定より長い存在する可能性もあります。特に新しいAudit Logのエントリが入ってこない時にです。



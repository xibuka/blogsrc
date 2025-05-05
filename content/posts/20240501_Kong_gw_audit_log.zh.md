---
title: "Kong Gateway 的审计日志（Audit Log）"
date: 2024-05-01T23:49:19+09:00
draft: false
tags:
- Kong Gateway
- Audit Log
---

## 概要

Kong 的审计日志（Audit Log）通过记录 Kong 执行的各类操作，为系统状态和安全性提供洞察。这使得系统变更、问题追踪以及安全事件检测成为可能。

Kong 的审计日志通常为 JSON 格式，记录的信息包括：

- 请求和响应数据
- 对路由和服务的访问尝试
- 用户或客户端的认证信息
- API Key 的使用情况
- 错误或警告信息
- 系统事件和配置变更

[https://docs.konghq.com/gateway/latest/kong-enterprise/audit-log/](https://docs.konghq.com/gateway/latest/kong-enterprise/audit-log/)

## 功能启用

Kong Audit Log 是 Enterprise 版本的功能，默认关闭。可通过修改 `audit_log` 参数来启用或禁用。

```conf
audit_log = on ## 启用审计日志
audit_log = off ## 关闭审计日志
```

## 使用方法

例如，执行如下访问：

```bash
curl -i -X GET http://localhost:8001/status
```

该访问会被记录到审计日志中，可通过如下请求获取：

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

如上所示，`rbac_user_id` 和 `rbac_user_name` 为 `null`，因为未启用 RBAC。如果启用 RBAC 后再次查看访问日志，会发现 `rbac_user_id` 和 `rbac_user_name` 有值，可以知道是谁访问的。

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

### 日志轮转

审计日志会在 Kong 数据库中保存一段时间，由 `audit_log_record_ttl` 参数定义。超过该时间的日志会被自动删除，默认值为 30 天。

在 PostgreSQL 中，只有在有新日志插入时才会触发自动删除。因此，如果长时间没有新日志写入，部分审计日志可能会比 TTL 设置存在更久。

---
title: "Audit Log in Kong Gateway"
date: 2024-05-01T23:49:19+09:00
draft: false
tags:
- Kong Gateway
- Audit Log
---

## Overview

Kong's Audit Log provides insights into the system's state and security by recording various operations performed by Kong. This enables tracking of system changes and issues, as well as detection of security breaches.

Kong's Audit Log is generally in JSON format and records information such as:

- Request and response data
- Access attempts to routes and services
- User or client authentication information
- API key usage
- Error or warning messages
- System events and configuration changes

[https://docs.konghq.com/gateway/latest/kong-enterprise/audit-log/](https://docs.konghq.com/gateway/latest/kong-enterprise/audit-log/)

## Enabling the Feature

Kong Audit Log is an Enterprise feature. It is off by default and can be enabled or disabled by changing the `audit_log` setting.

```conf
audit_log = on ## audit logging is enabled
audit_log = off ## audit logging is disabled
```

## How to Use

For example, if you make the following access:

```bash
curl -i -X GET http://localhost:8001/status
```

This access is recorded in the Audit Log and can be retrieved with the following request:

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

In the above case, `rbac_user_id` and `rbac_user_name` are `null` because RBAC is not enabled. If you check the access log again with RBAC enabled, you will see that `rbac_user_id` and `rbac_user_name` have values, so you can know who accessed it.

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

### Log Rotation

Audit Log entries are stored in Kong's DB for a period defined by `audit_log_record_ttl`. Logs older than this are automatically deleted. The default for this parameter is 30 days.

In PostgreSQL, automatic deletion occurs when there is an insert into the DB. Therefore, Audit Log entries may exist longer than the above TTL, especially if no new Audit Log entries are being added.

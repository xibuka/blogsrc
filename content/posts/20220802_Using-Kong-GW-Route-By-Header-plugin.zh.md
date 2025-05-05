---
title: "试用 Kong Gateway 的 Route By Header 插件"
date: 2022-08-03T01:19:02+09:00
draft: false
tags: 
- Kong Gateway
- Plugin
---

## 介绍

在 Kong Gateway 中，可以通过 Route 定义子路径，从而决定访问哪个 Service。例如，URL 末尾的子路径为 pathA 时，流量会被路由到 serviceA，最终访问 endpointA。

```text
http://mykong.org:8000/pathA => serviceA => endpointA
```

但有时我们希望根据请求更动态地决定转发目标，而不仅仅依赖子路径。这个插件允许你根据预定义的请求头和目标规则，动态决定转发目的地。规则有两个参数：`condition`（要匹配的头和取值）和 `upstream_name`（目标 Upstream 对象）。

```json
{"rules":[{"condition": {"location":"us-east"}, "upstream_name": "east.doamin.com"}]}
```

本文记录了该插件的实现方法。
注意：该插件只能通过 Admin API 管理，Kong Manager 无法操作。

<https://docs.konghq.com/hub/kong-inc/route-by-header/>

## 演示

下面实际体验一下该插件。首先创建一个用于演示的 `service` 和 `route`。`service` 的 endpoint 是 <http://httpbin.org/anything>，当没有命中任何插件规则时会访问它。

```bash
curl -i -X POST http://localhost:8001/services \
  --data protocol=http \
  --data host=httpbin.org \
  --date path=/anything
  --data name=demo

curl -i -X POST http://localhost:8001/routes  \
  --data "paths[]=/" \
  --data service.id=<上面创建的 service 的 id>
  --data name=demo
```

接着，准备两个 Upstream，`myip` 和 `date`，分别用于返回 IP 地址和当前时间。

```bash
curl -i -X POST http://localhost:8001/upstreams -d name=myip
curl -i -X POST http://localhost:8001/upstreams/myip/targets --data target="ip.jsontest.com:80"

curl -i -X POST http://localhost:8001/upstreams -d name=date
curl -i -X POST http://localhost:8001/upstreams/date/targets --data target="date.jsontest.com:80"
```

最后，在 route 上创建该插件。

```bash
curl -i -X POST http://localhost:8001/routes/demo/plugins \
  -H 'Content-Type: application/json' \
  --data '{"name": "route-by-header", "config": {"rules":[{"condition": {"info":"myip"}, "upstream_name": "myip"}, {"condition": {"info":"date"}, "upstream_name": "date"}]}}'
```

`--data` 部分是 Json 格式的路由规则。如果请求头包含 `info:myip`，则会被路由到 `myip` upstream；如果包含 `info:date`，则会被路由到 `date` upstream。

## 验证

请求头设置为 `info:myip` 时，请求被转发到 `myip` Upstream。

```bash
$ curl -i -X GET http://localhost:8000/ -H "info:myip"
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 24
Connection: keep-alive
Access-Control-Allow-Origin: *
X-Cloud-Trace-Context: d2c85f05ccd0e7d1273aee2476504cac
Date: Wed, 03 Aug 2022 04:23:29 GMT
Server: Google Frontend
X-Kong-Upstream-Latency: 212
X-Kong-Proxy-Latency: 0
Via: kong/2.8.1.2-enterprise-edition

{"ip": "18.181.83.240"}
```

请求头设置为 `info:date` 时，请求被转发到 `date` Upstream。

```bash
$ curl -i -X GET http://localhost:8000/ -H "info:date"
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 100
Connection: keep-alive
Access-Control-Allow-Origin: *
X-Cloud-Trace-Context: b03d154c04e8d788ae3c0d870ab9c2df
Date: Wed, 03 Aug 2022 04:23:33 GMT
Server: Google Frontend
X-Kong-Upstream-Latency: 214
X-Kong-Proxy-Latency: 0
Via: kong/2.8.1.2-enterprise-edition

{
   "date": "08-03-2022",
   "milliseconds_since_epoch": 1659500613301,
   "time": "04:23:33 AM"
}
```

如果请求头未设置（即不匹配任何规则），则会被转发到 service 的原始 endpoint <http://httpbin.org/anything>。

```bash
[ec2-user@ip-10-0-18-228 ~]$ curl -i -X GET http://localhost:8000/
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 419
Connection: keep-alive
Date: Wed, 03 Aug 2022 04:26:05 GMT
Server: gunicorn/19.9.0
Access-Control-Allow-Origin: *
Access-Control-Allow-Credentials: true
X-Kong-Upstream-Latency: 335
X-Kong-Proxy-Latency: 3
Via: kong/2.8.1.2-enterprise-edition

{
  "args": {},
  "data": "",
  "files": {},
  "form": {},
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.61.1",
    "X-Amzn-Trace-Id": "Root=1-62e9f8dd-7e352f095824a8b136de808a",
    "X-Forwarded-Host": "localhost",
    "X-Forwarded-Path": "/"
  },
  "json": null,
  "method": "GET",
  "origin": "127.0.0.1, 18.181.83.240",
  "url": "http://localhost/anything"
}
```

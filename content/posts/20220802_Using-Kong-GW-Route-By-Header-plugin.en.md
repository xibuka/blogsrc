---
title: "Trying Out Kong Gateway's Route By Header Plugin"
date: 2022-08-03T01:19:02+09:00
draft: false
tags: 
- Kong Gateway
- Plugin
---

## Introduction

In Kong Gateway, you can define subpaths in Routes to determine which Service to access. For example, if the subpath after the URL is pathA, traffic is routed to serviceA, which ultimately accesses endpointA.

```text
http://mykong.org:8000/pathA => serviceA => endpointA
```

However, sometimes you may want to determine the forwarding destination more dynamically, not just by subpath. This plugin uses pre-defined headers and destinations as rules, and determines the forwarding destination by looking at the request header information. The rule has two parameters: `condition` (the header and value to match) and `upstream_name` (the target Upstream object).

```json
{"rules":[{"condition": {"location":"us-east"}, "upstream_name": "east.doamin.com"}]}
```

This article is a memo about implementing this plugin.
Note: This plugin can only be managed via the Admin API. It cannot be managed in Kong Manager.

<https://docs.konghq.com/hub/kong-inc/route-by-header/>

## Demo

Let's actually use this plugin. First, create a working `service` and `route`. The endpoint of the `service` is <http://httpbin.org/anything>, which will be accessed if none of the plugin rules match.

```bash
curl -i -X POST http://localhost:8001/services \
  --data protocol=http \
  --data host=httpbin.org \
  --date path=/anything
  --data name=demo

curl -i -X POST http://localhost:8001/routes  \
  --data "paths[]=/" \
  --data service.id=<The id of service created above>
  --data name=demo
```

Next, prepare two Upstreams, `myip` and `date`, which will return the IP address and the current time, respectively, when accessed.

```bash
curl -i -X POST http://localhost:8001/upstreams -d name=myip
curl -i -X POST http://localhost:8001/upstreams/myip/targets --data target="ip.jsontest.com:80"

curl -i -X POST http://localhost:8001/upstreams -d name=date
curl -i -X POST http://localhost:8001/upstreams/date/targets --data target="date.jsontest.com:80"
```

Finally, create this plugin for the route.

```bash
curl -i -X POST http://localhost:8001/routes/demo/plugins \
  -H 'Content-Type: application/json' \
  --data '{"name": "route-by-header", "config": {"rules":[{"condition": {"info":"myip"}, "upstream_name": "myip"}, {"condition": {"info":"date"}, "upstream_name": "date"}]}}'
```

The `--data` part is a JSON rule for routing. If the header contains `info:myip`, it will be routed to the `myip` upstream; if it contains `info:date`, it will be routed to the `date` upstream.

## Verification

If you set the request header to `info:myip`, the request is forwarded to the `myip` Upstream.

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

If you set the request header to `info:date`, the request is forwarded to the `date` Upstream.

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

If you do not set the request header, i.e., if none of the rules match, the request is forwarded to the original service endpoint, <http://httpbin.org/anything>.

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

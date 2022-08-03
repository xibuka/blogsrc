---
title: "Kong Gatewayの Route By Header Pluginを使ってみる"
date: 2022-08-03T01:19:02+09:00
draft: false
---

## 紹介

Kong GatewayではRouteでサブパスを定義し、どのServiceにアクセスするかを決めています。例えば、以下のURLの後ろのサブパスがpathAの場合は、トラフィックがserviceAにルーティングされ、最終的に後ろにあるendpointAにアクセスされます。

```text
http://mykong.org:8000/pathA => serviceA => endpointA
```

しかし、サブパスではなくて、もっと動的にリクエストの転送先を決めたい場合があります。このプラグインは、事前に定義されたヘッダーと転送先をルールに、リクエストヘッダ情報を見て転送先を決めています。ルールに二つのパラメータがあり、`condition`は定義したヘッダーと値、`upstream_name`は転送先のUpstreamオブジェクトです。

```json
{"rules":[{"condition": {"location":"us-east"}, "upstream_name": "east.doamin.com"}]}
```

この記事では、このプラグインの実装についてメモします。
注：このプラグインを操作できるのはAdmin APIを通す方法のみ。Kong Managerでの操作はできない。

<https://docs.konghq.com/hub/kong-inc/route-by-header/>

## デモ

実際にこのプラグインを使ってみましょう。まずは作業用の`service`と`route`を作成する。`service`のendpointは<http://httpbin.org/anything> となりますが、このプラグインのルールに当てはまらない時にアクセスされます。

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

次に、転送先の`Upstream`を二つ用意し、`myip`と`date`をそれぞれアクセスするとIPアドレスと時間が表示されます。

```bash
curl -i -X POST http://localhost:8001/upstreams -d name=myip
curl -i -X POST http://localhost:8001/upstreams/myip/targets --data target="ip.jsontest.com:80"

curl -i -X POST http://localhost:8001/upstreams -d name=date
curl -i -X POST http://localhost:8001/upstreams/date/targets --data target="date.jsontest.com:80"
```

最後はrouteに対してこのプラグインを作ります。

```bash
curl -i -X POST http://localhost:8001/routes/demo/plugins \
  -H 'Content-Type: application/json' \
  --data '{"name": "route-by-header", "config": {"rules":[{"condition": {"info":"myip"}, "upstream_name": "myip"}, {"condition": {"info":"date"}, "upstream_name": "date"}]}}'
```

`--data`の部分はJsonで記載した振り分けのルールです。headerに`info:myip`が存在したら、`myip`のupstreamにふりわけされ、`info:date`が存在したら、`date`のupstreamに振り分けられます。

## 検証

リクエストのヘッダーに`info:myip`を設定したら、`myip`のUpstreamに転送されました。

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

リクエストのヘッダーに`info:date`を設定したら、`date`のUpstreamに転送されました。

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

リクエストのヘッダーを設定せず、つまりどのルールにも当てはまらない時は、serviceの元のendpoint、<http://httpbin.org/anything> に転送されました。

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

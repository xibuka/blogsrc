---
title: "试用 Kong 的 Canary Release 插件"
date: 2022-05-31T13:58:39+09:00
draft: false
tags: 
- Kong Gateway
- Canary
- Plugin
---
## 介绍

通过 Kong Gateway 的插件，可以非常方便地实现金丝雀发布。金丝雀发布不仅支持简单的百分比流量分配，还可以实现流量逐步扩大、白名单和黑名单等多种模式。

本文记录了金丝雀发布的操作方法。

<https://docs.konghq.com/hub/kong-inc/canary/>

## 创建 Service 和 Route

本次演示中，当前版本指向 <http://httpbin.org/xml>，新版本指向 <http://httpbin.org/json>。因此，访问当前版本时会返回 XML 响应，访问新版本时会返回 JSON 响应。

```bash
❯ http POST localhost:8001/services \
name=canary-api-service \
url=http://httpbin.org/xml

❯ http -f POST localhost:8001/services/canary-api-service/routes \
name=canary-api-route \
paths=/api/canary
```

验证效果，应该能收到 XML 响应：

```bash
❯ http GET localhost:8000/api/canary
HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Connection: keep-alive
Content-Length: 522
Content-Type: application/xml
Date: Wed, 25 May 2022 05:28:07 GMT
Server: gunicorn/19.9.0
Via: kong/2.8.1.0-enterprise-edition
X-Kong-Proxy-Latency: 0
X-Kong-Upstream-Latency: 295

<?xml version='1.0' encoding='us-ascii'?>

<!--  A SAMPLE set of slides  -->

<slideshow
    title="Sample Slide Show"
    date="Date of publication"
    author="Yours Truly"
    >

    <!-- TITLE SLIDE -->
    <slide type="all">
      <title>Wake up to WonderWidgets!</title>
    </slide>

    <!-- OVERVIEW -->
    <slide type="all">
        <title>Overview</title>
        <item>Why <em>WonderWidgets</em> are great</item>
        <item/>
        <item>Who <em>buys</em> WonderWidgets</item>
    </slide>

</slideshow>
```

## 金丝雀发布模式

### 按时间渐进（Set a Period）

该模式允许你指定发布的开始时间和过渡时长。发布初期几乎所有流量都走当前版本，随后新版本流量逐步增加，最终全部切换到新版本。

如下命令中，发布将在 `10` 秒后开始，过渡时长为 `120` 秒。

```bash
❯ current_time=`expr $(date "+%s") + 10` && http -f POST http://localhost:8001/routes/canary-api-route/plugins \
name=canary \
config.start=$current_time \
config.duration=120 \
config.upstream_host=httpbin.org \
config.upstream_port=80 \
config.upstream_uri=/json \
config.hash=none
```

此时运行下列命令，最初会收到 XML 响应，随后 JSON 响应会逐渐增多，最终全部为 JSON 响应。

```bash
❯ for num in {1..70}; do
 echo "Calling API #$num"
 http http://localhost:8000/api/canary
 sleep 0.5
done
```

```bash
❯ http GET localhost:8000/api/canary
HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Connection: keep-alive
Content-Length: 429
Content-Type: application/json
Date: Wed, 25 May 2022 07:27:08 GMT
Server: gunicorn/19.9.0
Via: kong/2.8.1.0-enterprise-edition
X-Kong-Proxy-Latency: 4
X-Kong-Upstream-Latency: 284

{
    "slideshow": {
        "author": "Yours Truly",
        "date": "date of publication",
        "slides": [
            {
                "title": "Wake up to WonderWidgets!",
                "type": "all"
            },
            {
                "items": [
                    "Why <em>WonderWidgets</em> are great",
                    "Who <em>buys</em> WonderWidgets"
                ],
                "title": "Overview",
                "type": "all"
            }
        ],
        "title": "Sample Slide Show"
    }
}
```

验证通过后，可以删除金丝雀插件，测试下一个发布模式：

```bash
❯ plugin_id=$(http -f http://localhost:8001/routes/canary-api-route/plugins | jq -r '.data[].id') &&  http DELETE http://localhost:8001/plugins/$plugin_id
```

### 按百分比分流（Set a Percentage）

该模式下，当前版本和新版本的流量分配比例保持不变。你设置的百分比决定了新版本的流量占比。

如下命令中，`config.percentage` 设为 50，表示新旧版本各占一半流量。

```bash
❯ http -f POST http://localhost:8001/routes/canary-api-route/plugins \
name=canary \
config.percentage=50 \
config.upstream_host=httpbin.org \
config.upstream_port=80 \
config.upstream_uri=/json \
config.hash=none
```

运行下列命令，应该能看到两种响应各占一半左右：

```bash
❯ for num in {1..10}; do
 echo "Calling API #$num"
 http http://localhost:8000/api/canary
 sleep 0.5
done
```

如需逐步调整百分比，可用如下命令更新插件：

```bash
$ plugin_id=$(http -f http://localhost:8001/routes/canary-api-route/plugins | jq -r '.data[].id')
$ http -f PUT http://localhost:8001/routes/canary-api-route/plugins/$plugin_id \
name=canary \
config.percentage=90 \
config.upstream_host=httpbin.org \
config.upstream_port=80 \
config.upstream_uri=/json \
config.hash=none
```

验证通过后，可以删除金丝雀插件，测试下一个发布模式：

```bash
❯ plugin_id=$(http -f http://localhost:8001/routes/canary-api-route/plugins | jq -r '.data[].id') &&  http DELETE http://localhost:8001/plugins/$plugin_id
```

### 白名单与黑名单（Whitelist and Blacklist）

该模式下，可以通过请求中的 `API Key` 识别用户（Consumer），并根据其所属分组决定访问哪个版本。可结合 `key-auth` 和 `acl` 插件实现。

首先注册 `key-auth` 插件，未携带 API key 的请求将被拒绝：

```bash
❯ http http://localhost:8001/routes/canary-api-route/plugins name=key-auth
```

然后创建两类 Consumer，并分别加入不同分组：

```bash
❯ http :8001/consumers username=vip-consumer && http :8001/consumers/vip-consumer/key-auth key=vip-api && http :8001/consumers/vip-consumer/acls group=vip-acl

❯ http :8001/consumers username=general-consumer && http :8001/consumers/general-consumer/key-auth key=general-api && http :8001/consumers/general-consumer/acls group=general-acl
```

完成上述设置后，基于分组信息创建金丝雀插件。注意 `config.hash` 必须设置为 `whitelist` 或 `blacklist`，在 `whitelist` 中的分组会被路由到新版本。

```bash
❯ http -f POST http://localhost:8001/routes/canary-api-route/plugins \
name=canary \
config.hash=whitelist \
config.groups=vip-acl \
config.upstream_host=httpbin.org \
config.upstream_port=80 \
config.upstream_uri=/json
```

携带 `vip-api` key 的客户端（即 vip-acl 分组）会被路由到新版本：

```bash
❯ http http://localhost:8000/api/canary apiKey:vip-api
HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Connection: keep-alive
Content-Length: 429
Content-Type: application/json
Date: Wed, 25 May 2022 07:33:45 GMT
Server: gunicorn/19.9.0
Via: kong/2.8.1.0-enterprise-edition
X-Kong-Proxy-Latency: 118
X-Kong-Upstream-Latency: 290

{
    "slideshow": {
        "author": "Yours Truly",
        "date": "date of publication",
        "slides": [
            {
                "title": "Wake up to WonderWidgets!",
                "type": "all"
            },
            {
                "items": [
                    "Why <em>WonderWidgets</em> are great",
                    "Who <em>buys</em> WonderWidgets"
                ],
                "title": "Overview",
                "type": "all"
            }
        ],
        "title": "Sample Slide Show"
    }
}
```

携带 `general-api` key 的客户端（即 general-acl 分组）会被路由到当前版本：

```bash
❯ http http://localhost:8000/api/canary apiKey:general-api
HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Connection: keep-alive
Content-Length: 522
Content-Type: application/xml
Date: Wed, 25 May 2022 07:33:55 GMT
Server: gunicorn/19.9.0
Via: kong/2.8.1.0-enterprise-edition
X-Kong-Proxy-Latency: 5
X-Kong-Upstream-Latency: 289

<?xml version='1.0' encoding='us-ascii'?>

<!--  A SAMPLE set of slides  -->

<slideshow
    title="Sample Slide Show"
    date="Date of publication"
    author="Yours Truly"
    >

    <!-- TITLE SLIDE -->
    <slide type="all">
      <title>Wake up to WonderWidgets!</title>
    </slide>

    <!-- OVERVIEW -->
    <slide type="all">
        <title>Overview</title>
        <item>Why <em>WonderWidgets</em> are great</item>
        <item/>
        <item>Who <em>buys</em> WonderWidgets</item>
    </slide>

</slideshow>
```

## 完成升级

金丝雀发布测试无误后，可以将所有流量切换到新版本：只需更新 service 的上游地址并删除金丝雀插件。

```bash
# 更新 service
❯ http -f PUT :8001/services/canary-api-service url=http://httpbin.org/json
# 删除所有插件
❯ http http://localhost:8001/routes/canary-api-route/plugins | jq -r -c '.data[].id' | while read id; do
    http --ignore-stdin DELETE http://localhost:8001/plugins/$id
done
```

至此，通过金丝雀发布完成了新版本服务的升级！

```bash
❯ http http://localhost:8000/api/canary
HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Connection: keep-alive
Content-Length: 429
Content-Type: application/json
Date: Wed, 25 May 2022 07:35:55 GMT
Server: gunicorn/19.9.0
Via: kong/2.8.1.0-enterprise-edition
X-Kong-Proxy-Latency: 4
X-Kong-Upstream-Latency: 288

{
    "slideshow": {
        "author": "Yours Truly",
        "date": "date of publication",
        "slides": [
            {
                "title": "Wake up to WonderWidgets!",
                "type": "all"
            },
            {
                "items": [
                    "Why <em>WonderWidgets</em> are great",
                    "Who <em>buys</em> WonderWidgets"
                ],
                "title": "Overview",
                "type": "all"
            }
        ],
        "title": "Sample Slide Show"
    }
}
```

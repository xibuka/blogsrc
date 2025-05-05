---
title: "KongのCanary Release pluginを使ってみる"
date: 2022-05-31T13:58:39+09:00
draft: false
tags: 
- Kong Gateway
- Canary
- Plugin
---
## 紹介

Kong Gatewayのプラグインを利用すれば、カナリアリリースが簡単に設定することができます。しかもカナリアリリースのモードは単なるパーセンテージではなく、徐々に利用拡大や、Writelist&blacklistの設定もできます。

この記事では、カナリアリリースのやり方についてメモします。

<https://docs.konghq.com/hub/kong-inc/canary/>

## ServiceとRouteの作成

デモの例として、現在のバージョンを<http://httpbin.org/xml>に、新規リリースのバージョンを<http://httpbin.org/json>にします。なので、現在のバージョンの場合は、xmlのレスポンス、新規リリースのバージョンの場合は、jsonのレスポンスが帰ってくるはず。

```bash
❯ http POST localhost:8001/services \
name=canary-api-service \
url=http://httpbin.org/xml

❯ http -f POST localhost:8001/services/canary-api-service/routes \
name=canary-api-route \
paths=/api/canary
```

動作確認、xmlのレスポンスが帰ってきた。

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

## カナリアリリースモード

### 一定期間(Set a Period)

翻訳が合っているかどうかが分からないが、リリースの開始時刻と移行期間を決めるモードです。リリース期間の初期段階はほとんど現バージョンで、そして徐々に新バージョンの出現確率が高くなり、最終的に新バージョンのみになるモードです。

以下のコマンドの設定から、リリースの開始が`10`秒後、移行期間が`120`秒となります。

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

この設定で以下のコマンドを実行すると、最初はxmlのレスポンスになるが、徐々にJsonの方が増えていて、最終的に全部Jsonのレスポンスになります。

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

これで動作確認が終わったので、次のリリース方式をテストするために、カナリアリリースプラグインを削除する

```bash
❯ plugin_id=$(http -f http://localhost:8001/routes/canary-api-route/plugins | jq -r '.data[].id') &&  http DELETE http://localhost:8001/plugins/$plugin_id
```

### 一定割合(Set a Percentage)

トラフィックが現バージョンと新バージョンにアクセスする確率を一定にするモードです。設定した割合はパーセンテージであり、新バージョンにアクセスする割合となります。

以下のコマンドの設定、config.percentageから、現バージョンと新バージョンの割合が５割５割となっています。

```bash
❯ http -f POST http://localhost:8001/routes/canary-api-route/plugins \
name=canary \
config.percentage=50 \
config.upstream_host=httpbin.org \
config.upstream_port=80 \
config.upstream_uri=/json \
config.hash=none
```

以下のコマンドで確認すると、大体ですけど半分ずつとなっているはずです。

```bash
❯ for num in {1..10}; do
 echo "Calling API #$num"
 http http://localhost:8000/api/canary
 sleep 0.5
done
```

もしパーセンテージのテストを段階的に行いたい場合、以下のコマンドで割合を変更することもできます。

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

これで動作確認が終わったので、次のリリース方式をテストするために、カナリアリリースプラグインを削除する

```bash
❯ plugin_id=$(http -f http://localhost:8001/routes/canary-api-route/plugins | jq -r '.data[].id') &&  http DELETE http://localhost:8001/plugins/$plugin_id
```

### Whitelist and Blacklist

こちらのモードでは、リクエストに含まれた`API Key`でユーザ`Consumer`を特定し、`Consumer`が所属するグループに基づいてどのバージョンにアクセスしにいくのかを設定できます。
`Consumer`の特定とグループの登録は、`key-auth`と`acl`のプラグインを利用します。

まずは`key-auth`のプラグインを登録し、これで`API key`なしだとアクセスができなくなります。

```bash
❯ http http://localhost:8001/routes/canary-api-route/plugins name=key-auth
```

次に、今回は２種類の`Consumer`を準備し、それぞれ別のグループに登録します。

```bash
❯ http :8001/consumers username=vip-consumer && http :8001/consumers/vip-consumer/key-auth key=vip-api && http :8001/consumers/vip-consumer/acls group=vip-acl

❯ http :8001/consumers username=general-consumer && http :8001/consumers/general-consumer/key-auth key=general-api && http :8001/consumers/general-consumer/acls group=general-acl
```

上の設定が終わったら、グループ情報を用いてカナリアリリースプラグインを作成します。
ここで注意してほしいのは、`config.hash`です。`whitelist`か`blacklist`を設定する必要がありまして、`whitelist`に設定したグループは新バージョンにアクセスしにいきます。

```bash
❯ http -f POST http://localhost:8001/routes/canary-api-route/plugins \
name=canary \
config.hash=whitelist \
config.groups=vip-acl \
config.upstream_host=httpbin.org \
config.upstream_port=80 \
config.upstream_uri=/json
```

`vip-api`を持ってアクセスするクライアント、つまり`Consumer`のグループは`vip-acl`であり、`whitelist`に登録されているので新バージョンにアクセスしにいきます。

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

一方、`general-api`を持ってアクセスするクライアント、つまり`Consumer`のグループは`general-acl`のため、現バージョンにアクセスしにいきます。

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

## アップグレードを完了させる

カナリアリリースのテストが終わったら、特に問題がない場合、全てのトラフィックをプラグインなしで新バージョンにrouteしていきたい。

そこで実行すべきのは、serviceのUpstream Endpointを更新し、カナリアリリースプラグインを削除することです。

```bash
# update service
❯ http -f PUT :8001/services/canary-api-service url=http://httpbin.org/json
# delete all plugins
❯ http http://localhost:8001/routes/canary-api-route/plugins | jq -r -c '.data[].id' | while read id; do
    http --ignore-stdin DELETE http://localhost:8001/plugins/$id
done
```

これでカナリアリリースで新バージョンのサービスのアップグレードが完了した！

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

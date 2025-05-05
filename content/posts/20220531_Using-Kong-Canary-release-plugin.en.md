---
title: "Trying Out Kong's Canary Release Plugin"
date: 2022-05-31T13:58:39+09:00
draft: false
tags: 
- Kong Gateway
- Canary
- Plugin
---
## Introduction

With Kong Gateway plugins, you can easily set up canary releases. The canary release modes are not just simple percentages; you can also gradually increase traffic or configure whitelists and blacklists.

This article is a memo on how to perform canary releases.

<https://docs.konghq.com/hub/kong-inc/canary/>

## Creating Service and Route

For this demo, the current version will point to <http://httpbin.org/xml>, and the new release version will point to <http://httpbin.org/json>. So, if you hit the current version, you'll get an XML response; if you hit the new version, you'll get a JSON response.

```bash
❯ http POST localhost:8001/services \
name=canary-api-service \
url=http://httpbin.org/xml

❯ http -f POST localhost:8001/services/canary-api-service/routes \
name=canary-api-route \
paths=/api/canary
```

To check if it's working, you should get an XML response:

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

## Canary Release Modes

### Set a Period

This mode lets you specify a release start time and a transition period. At the beginning of the period, almost all traffic goes to the current version, but gradually, more traffic is routed to the new version, and eventually, all traffic goes to the new version.

In the following command, the release starts in `10` seconds, and the transition period is `120` seconds.

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

With this setting, if you run the following command, you'll initially get XML responses, but gradually you'll see more JSON responses, and eventually, all responses will be JSON.

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

After confirming this works, you can delete the canary release plugin to test the next release mode:

```bash
❯ plugin_id=$(http -f http://localhost:8001/routes/canary-api-route/plugins | jq -r '.data[].id') &&  http DELETE http://localhost:8001/plugins/$plugin_id
```

### Set a Percentage

This mode keeps the probability of accessing the current and new versions constant. The percentage you set determines the proportion of traffic routed to the new version.

In the following command, `config.percentage` is set to 50, so traffic is split 50/50 between the current and new versions.

```bash
❯ http -f POST http://localhost:8001/routes/canary-api-route/plugins \
name=canary \
config.percentage=50 \
config.upstream_host=httpbin.org \
config.upstream_port=80 \
config.upstream_uri=/json \
config.hash=none
```

If you run the following command, you should see about half the responses from each version:

```bash
❯ for num in {1..10}; do
 echo "Calling API #$num"
 http http://localhost:8000/api/canary
 sleep 0.5
done
```

If you want to gradually change the percentage, you can update the plugin as follows:

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

After confirming this works, you can delete the canary release plugin to test the next release mode:

```bash
❯ plugin_id=$(http -f http://localhost:8001/routes/canary-api-route/plugins | jq -r '.data[].id') &&  http DELETE http://localhost:8001/plugins/$plugin_id
```

### Whitelist and Blacklist

In this mode, you can identify users (Consumers) by the `API Key` in the request and control which version they access based on the group they belong to. Use the `key-auth` and `acl` plugins to identify consumers and assign groups.

First, register the `key-auth` plugin so that access without an API key is not allowed:

```bash
❯ http http://localhost:8001/routes/canary-api-route/plugins name=key-auth
```

Next, create two types of consumers and assign them to different groups:

```bash
❯ http :8001/consumers username=vip-consumer && http :8001/consumers/vip-consumer/key-auth key=vip-api && http :8001/consumers/vip-consumer/acls group=vip-acl

❯ http :8001/consumers username=general-consumer && http :8001/consumers/general-consumer/key-auth key=general-api && http :8001/consumers/general-consumer/acls group=general-acl
```

After this setup, create the canary release plugin using the group information. Note that you must set `config.hash` to either `whitelist` or `blacklist`. Groups listed in `whitelist` will be routed to the new version.

```bash
❯ http -f POST http://localhost:8001/routes/canary-api-route/plugins \
name=canary \
config.hash=whitelist \
config.groups=vip-acl \
config.upstream_host=httpbin.org \
config.upstream_port=80 \
config.upstream_uri=/json
```

Clients with the `vip-api` key (i.e., consumers in the `vip-acl` group) will be routed to the new version:

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

Clients with the `general-api` key (i.e., consumers in the `general-acl` group) will be routed to the current version:

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

## Completing the Upgrade

After testing the canary release, if there are no issues, you can route all traffic to the new version by updating the service's upstream endpoint and deleting the canary release plugin.

```bash
# update service
❯ http -f PUT :8001/services/canary-api-service url=http://httpbin.org/json
# delete all plugins
❯ http http://localhost:8001/routes/canary-api-route/plugins | jq -r -c '.data[].id' | while read id; do
    http --ignore-stdin DELETE http://localhost:8001/plugins/$id
done
```

Now the upgrade to the new version via canary release is complete!

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

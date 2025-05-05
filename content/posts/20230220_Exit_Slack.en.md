---
title: "Implemented with Kong Gateway! Notify via Slack Webhook on Request Failure"
date: 2023-02-20T14:21:23+09:00
draft: false
tags: 
- Kong Gateway
- WebHook
- plugin
---
## Background

When accessing APIs via Kong Gateway, you may want to be notified if a request fails. The usual approach is to save logs with a logging plugin and then set up alerts and notifications using a third-party product (like ELK). However, using other products can be cumbersome to deploy, require licenses and extra configuration, and ideally, you'd like to achieve this within Kong itself. In this article, I'll show how to use the [`Exit Transformer`](https://docs.konghq.com/hub/kong-inc/exit-transformer/) plugin to trigger a Slack Webhook via Lua script when a request results in an error. This plugin allows you to transform and customize Kong's response messages using Lua functions. You can change the message, status code, headers, or even completely transform the response structure.

## Trying the Plugin

Let's start by trying the example from the documentation.

### Create Service and Route

```bash
http :8001/services name=example.com host=mockbin.org
http -f :8001/services/example.com/routes hosts=example.com
```

### Add key-auth Plugin to Force Failure

```bash
http :8001/services/example.com/plugins name=key-auth
```

### Create Lua Script

The following code adds the header `x-some-header` and appends `, arr` to the end of the message. Save this as `transform.lua`.

```lua
    -- transform.lua
    return function(status, body, headers)
      if not body or not body.message then
        return status, body, headers
      end

      headers = { ["x-some-header"] = "some value" }
      local new_body = {
        error = true,
        status = status,
        message = body.message .. ", arr!",
      }

      return status, new_body, headers
    end
```

### Deploy the Plugin with the Script

```bash
http -f :8001/services/example.com/plugins \
     name=exit-transformer \
     config.functions=@transform.lua
```

### Test

After setting up, try accessing the service. The header and the `arr` message should be added to the response.

```bash
❯ http :8000 Host:example.com
HTTP/1.1 401 Unauthorized
Connection: keep-alive
Content-Length: 73
Content-Type: application/json; charset=utf-8
Date: Fri, 10 Feb 2023 07:36:15 GMT
Server: kong/3.1.1.3-enterprise-edition
WWW-Authenticate: Key realm="kong"
X-Kong-Response-Latency: 2
x-some-header: some value

{
    "error": true,
    "message": "No API key found in request, arr!",
    "status": 401
}
```

## Implementing Webhook in the Script

This time, we'll use Slack's Webhook. After adding content to the message, the script will trigger the webhook.

```lua
...
      local httpc = require("resty.http").new()

      -- Single-shot requests use the `request_uri` interface.
      local res, err = httpc:request_uri("https://hooks.slack.com/services/xxxxxx/xxxxxx/xxxxxxxx", {
          method = "POST",
          body = '{"text": "Hello, world."}',
          headers = {
              ["Content-Type"] = "application/json",
          },
      })
      if not res then
          ngx.log(ngx.ERR, "request failed: ", err)
          return
      end

      return status, new_body, headers
...
```

To send the request, we use [lua-resty-http](https://github.com/ledgetech/lua-resty-http). Normally, you use `require` to make the request, but there is a concern that it may not work well with the nginx event loop. That is, while waiting for a response from hooks.slack.com, nginx may not be able to process other requests.

Another thing to note is that since an external library is being called, you need to set the [untrusted_lua](https://docs.konghq.com/gateway/latest/reference/configuration/#untrusted_lua) parameter to On. Otherwise, you'll get an error like this:

```log
2023/02/10 02:19:13 [error] 2175#0: *15812 lua entry thread aborted: runtime error: /usr/local/share/lua/5.1/kong/tools/sandbox.lua:88: require 'ssl.https' not allowed within sandbox
```

## Test Again

Now, access the API again and check the Slack message!

```bash
❯ http :8000 Host:example.com
HTTP/1.1 401 Unauthorized
Connection: keep-alive
Content-Length: 73
Content-Type: application/json; charset=utf-8
Date: Mon, 13 Feb 2023 13:28:42 GMT
Server: kong/3.1.1.3-enterprise-edition
WWW-Authenticate: Key realm="kong"
X-Kong-Response-Latency: 0
x-some-header: some value

{
    "error": true,
    "message": "No API key found in request, arr!",
    "status": 401
}
```

![iShot_2023-02-13_22.29.31.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/1ec6a8fc-bbe2-550a-9fe9-190aa2c34b73.png)

It worked!!

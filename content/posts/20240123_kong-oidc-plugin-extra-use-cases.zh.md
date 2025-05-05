---
title: "Kong OpenID Connect 插件的其他使用案例"
date: 2024-01-23T22:55:37+09:00
draft: false
tags:
- Kong Gateway
- plugin
- OpenID
---

（翻译自 [https://tech.aufomm.com/kong-oidc-plugin-extra-use-cases/](https://tech.aufomm.com/kong-oidc-plugin-extra-use-cases/) ）

Kong 的 OIDC 插件非常强大且复杂（有近 200 个参数……），如果你知道需要怎样的参数组合，可以实现更多功能。本文介绍一些实际使用场景，帮助你更好地用好这个插件。

注：我使用的是 Kong Gateway (Enterprise) 2.4.1.1 版本。

> 前置条件
>
> - Kong Gateway (Enterprise)
> - 已有 OIDC 服务器（本文以 Keycloak 为例）。如果不会用 Keycloak，可以参考我之前的文章。

## 从 IDP Token 提取数据并添加到 Header

如果你想把 IDP token 里的值映射到上游 header，可以用 `config.upstream_headers_names` 和 `config.upstream_headers_claims`。

比如 JWT token 的 payload 如下：

```json
{
  "payload": {
    "kong-test": "to-upstream"
  }
}
```

目标是把 `to-upstream` 这个值映射到 header `kong-test`，并传递给上游服务器。OIDC 插件可以这样配置（以 password flow 为例）：

```bash
curl --request POST \
  --url http://kong.li.lan:8001/plugins \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data name=openid-connect \
  --data config.issuer=https://<keycloak>/auth/realms/demo \
  --data config.client_id=<client_id> \
  --data config.client_secret=<client_secret> \
  --data config.auth_methods=password \
  --data config.upstream_headers_claims=kong-test \
  --data config.upstream_headers_names=test_kong 
```

用用户名和密码调用 API 后，上游服务器收到的请求 header 应如下：

```json
"Test-Kong": "to-upstream",
```

如果值是对象（比如要把员工信息传递到上游 header），会被 base64 编码。

```json
{
  "payload": {
    "employee": {
      "favourites": {
        "beverage": "coffee"
      },
      "groups": [
        "default",
        "it"
      ],
      "name": "li"
    }
  }
}
```

启用插件：

```bash
curl --request POST \
  --url http://kong.li.lan:8001/plugins \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data name=openid-connect \
  --data config.issuer=https://<keycloak>/auth/realms/demo \
  --data config.client_id=<client_id> \
  --data config.client_secret=<client_secret> \
  --data config.auth_methods=password \
  --data config.upstream_headers_claims=employee \
  --data config.upstream_headers_names=x-employee-info
```

认证后，上游会收到如下 header：

```bash
"X-Employee-Info": [
  "eyJuYW1lIjoibGkiLCJmYXZvdXJpdGVzIjp7ImJldmVyYWdlIjoiY29mZmVlIn0sImdyb3VwcyI6WyJkZWZhdWx0IiwiaXQiXX0="
]
```

## 检查收到的 Token

有时 OIDC 插件配置有问题，但日志里看不到关键信息。例如日志出现 kong failed to find the consumer for consumer mapping，但 token 里其实有相关信息（比如请求没带 scope，claim 没被加进去）。

此时最好的调试方法是直接查看 IDP 返回的 token。只需设置 `config.login_action=response` 和 `config.login_tokens=tokens`。

例如：

1. 用 `authorization_code flow` 启用 OIDC 插件：

    ```bash
    curl --request POST \
    --url http://kong.li.lan:8001/plugins \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --data name=openid-connect \
    --data config.issuer=https://<keycloak>/auth/realms/demo \
    --data config.client_id=<client_id> \
    --data config.client_secret=<client_secret> \
    --data config.auth_methods=authorization_code \
    --data config.login_action=response \
    --data config.login_tokens=tokens
    ```

2. 用浏览器访问 `https://<kong_proxy>/<oidc_protected_route>`。
3. 登录后即可看到 IDP 返回的 token。

## 多个必需的 Claim

如果应用要求 JWT token 里某些 claim 必须有特定值，可以用以下 4 对参数校验 JWT：

- `config.groups_claim` 和 `config.groups_required`
- `config.scopes_claim` 和 `config.scopes_required`
- `config.roles_claim` 和 `config.roles_required`
- `config.audience_claim` 和 `config.audience_required`

参数名无所谓，可以随意指定 claim。注意：

- 最多同时校验 4 个 claim。
- 同一 claim 可用 OR/AND 逻辑校验多个值。
- claim 名支持数组/对象嵌套。

比如 JWT token 里有如下 `employee` claim：

```json
"employee": {
  "name": "li",
  "groups": [
    "default",
    "it"
  ],
  "favourites": {
    "beverage": "coffee"
  }
}
```

### 校验 claim 数组所有值

只允许喜欢喝咖啡的员工访问，可以这样启用 OIDC 插件：

```bash
curl --request POST \
  --url http://kong.li.lan:8001/plugins \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data name=openid-connect \
  --data config.issuer=https://<keycloak>/auth/realms/demo \
  --data config.client_id=<client_id> \
  --data config.client_secret=<client_secret> \
  --data config.auth_methods=password \
  --data config.scopes_required=coffee \
  --data config.scopes_claim=employee \
  --data config.scopes_claim=favourites \
  --data config.scopes_claim=beverage
```

如上，`"scopes_claim":["employee", "favorites", "beverage"]` 配成数组，`config.scopes_required=coffee`。Kong 会检查 JWT claim，判断 `beverage` 是否等于 `coffee`。如果不是，用户会收到 `HTTP/1.1 403 Forbidden`。

### 校验某 claim 的多个值

- AND
只允许同时属于 `default` 和 `it` 组的用户访问：

```bash
curl --request POST \
  --url http://kong.li.lan:8001/plugins \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data name=openid-connect \
  --data config.issuer=https://<keycloak>/auth/realms/demo \
  --data config.client_id=<client_id> \
  --data config.client_secret=<client_secret> \
  --data config.auth_methods=password \
  --data 'config.scopes_required=default it' \
  --data config.scopes_claim=employee \
  --data config.scopes_claim=groups
```

- OR
只要属于 `default` 或 `it` 组的用户都能访问：

```bash
curl --request POST \
--url http://kong.li.lan:8001/plugins \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data name=openid-connect \
--data config.issuer=https://<keycloak>/auth/realms/demo \
--data config.client_id=<client_id> \
--data config.client_secret=<client_secret> \
--data config.auth_methods=password \
--data 'config.scopes_required=default' \
--data 'config.scopes_required=it' \
--data config.scopes_claim=employee \
--data config.scopes_claim=groups
```

关键在于 `config.scopes_required`。不同数组下标是 OR，同一数组下标用空格分隔是 AND。

## 给认证端点传递额外参数

用 authorization code flow 时，重定向 URL 上无关的 query 参数会被移除。可以用如下参数给认证端点的 query string 添加额外参数。

### 添加变量值

比如想把用户名或邮箱传给 IDP，可以设置 `config.authorization_query_args_client`。

```bash
curl --request POST \
  --url http://kong.li.lan:8001/plugins \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data name=openid-connect \
  --data config.issuer=https://<keycloak>/auth/realms/demo \
  --data config.client_id=<client_id> \
  --data config.client_secret=<client_secret> \
  --data config.auth_methods=authorization_code \
  --data config.authorization_query_args_client=username 
```

然后访问 `https://<kong_proxy>/<protected_route>?username=admin`，你会看到 username=admin 被加进去了。

### 添加固定值

如果要加固定参数，可以用 `config.authorization_query_args_names` 和 `config.authorization_query_args_values` 配对添加。

```bash
curl --request POST \
  --url http://kong.li.lan:8001/plugins \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data name=openid-connect \
  --data config.issuer=https://<keycloak>/auth/realms/demo \
  --data config.client_id=<client_id> \
  --data config.client_secret=<client_secret> \
  --data config.auth_methods=authorization_code \
  --data config.authorization_query_args_names=user \
  --data config.authorization_query_args_values=demo
```

此时访问 `https://<kong_proxy>/<protected_route>`，认证 URL 上会有 `user=demo`。

今天就分享到这里，下次介绍 OIDC 客户端认证的用法。

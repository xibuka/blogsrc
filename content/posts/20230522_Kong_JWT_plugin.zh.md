---
title: "Kong Gateway 的 JWT 插件使用实践"
date: 2023-05-22T00:33:31+09:00
draft: false
tags:
- Kong Gateway
- plugin
- JWT
---

（翻译自 [https://tech.aufomm.com/how-to-use-jwt-plugin/](https://tech.aufomm.com/how-to-use-jwt-plugin/) ）

Kong 有很多认证插件，本文介绍 JWT 插件的用法。

## 使用示例

### 创建 Service

```bash
curl -X POST http://localhost:8001/services \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, */*" \
  -d '{"name":"jwt-service","url":"https://httpbin.org/anything"}'
```

### 创建 Route

```bash
curl -X POST http://localhost:8001/services/jwt-service/routes \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, */*" \
  -d '{"name":"jwt-route","paths":["/jwt"]}'
```

用 `curl 'http://localhost:8000/jwt' -i` 访问路由，应该返回 `HTTP/1.1 200 OK`。

### 启用 JWT 插件

:::note
该插件可以按 Service 或全局启用。
:::

```bash
curl --request POST \
  --url http://localhost:8001/plugins \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data name=jwt
```

再次访问上面的路由，应该返回 `HTTP/1.1 401 Unauthorized`。

### 创建 Consumer

创建一个 consumer 用于持有 JWT 认证信息。

```bash
curl --request POST \
  --url http://localhost:8001/consumers \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data username=jwt-user
```

### 创建 JWT 认证信息

JWT 插件支持 5 种算法，主要区别在于密钥的共享方式。RS256 生成的是非对称密钥，HS256 用对称密钥签名。下面分别演示 HS256 和 RS256。算法区别可参考 [Auth0 文档](https://community.auth0.com/t/rs256-vs-hs256-jwt-signing-algorithms/58609)。

#### HS256

- 用 Kong 生成 key 和 secret

```bash
curl -X POST http://localhost:8001/consumers/jwt-user/jwt
```

默认 Kong 用 `HS256` 算法生成 `Key` 和 `Secret`。

```json
{
  "algorithm": "HS256",
  "id": "a5f72a73-daa6-440d-8257-a40c37d34ec8",
  "key": "Yb7adJK7ZTcSxEd9r7KKl8VOJ3pY44w1",
  "consumer": {
    "id": "297e8e1f-1d56-4369-97f9-4765efb853fe"
  },
  "tags": null,
  "secret": "h1Hc2orJlm8aJIefXvIYcdJ3GVfwtcu2",
  "created_at": 1607151650,
  "rsa_public_key": null
}
```

- 使用自定义 key 和 secret

用 pwgen 生成两个密码。

```bash
pwgen -sBv 32 2
Mt4RTRWJk9pfWJpgthP4sHhcqR4hFKzK J3NKsJgt79tcLRfLWwVMJvVnTFk7WskW
```

第一个作为 `key`，第二个作为 `secret`。同一个 consumer 可以创建多个密钥对。

```bash
curl --request POST \
  --url http://localhost:8001/consumers/jwt-user/jwt \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data key=Mt4RTRWJk9pfWJpgthP4sHhcqR4hFKzK \
  --data secret=J3NKsJgt79tcLRfLWwVMJvVnTFk7WskW
```

会看到如下返回：

```json
{
  "algorithm": "HS256",
  "id": "711c7b54-5551-4803-abc6-cb7ff86b0858",
  "key": "Mt4RTRWJk9pfWJpgthP4sHhcqR4hFKzK",
  "consumer": {
    "id": "297e8e1f-1d56-4369-97f9-4765efb853fe"
  },
  "tags": null,
  "secret": "J3NKsJgt79tcLRfLWwVMJvVnTFk7WskW",
  "created_at": 1607152864,
  "rsa_public_key": null
}
```

接下来可用 [JWT debugger](https://jwt.io/) 或 [JWT CLI](https://github.com/mike-engel/jwt-cli) 生成 token，payload 里要有 iss: ${key}。拿到 token 后作为 Bearer 头访问 API 即可。

```bash
curl http://localhost:8000/jwt \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJNdDRSVFJXSms5cGZXSnBndGhQNHNIaGNxUjRoRkt6SyJ9.pCV1wm3VixWkZ_Nh24v4RSQjvYhpb5vJp_LeTRZnF2o"
```

#### RS256

- 自己生成认证文件

  - 生成私钥和公钥

  ```bash
  openssl genrsa -out jwt-private.pem 2048 2>/dev/null &&\
  openssl rsa -in jwt-private.pem -outform PEM -pubout -out jwt-public.pem 2>/dev/null &&\
  echo -e 'Your private key is \033[1;4mjwt-private.pem\033[0m and public key is 
  \033[1;4mjwt-public.pem\033[0m'
  ```

  执行后当前目录下会有 `jwt-private.pem` 和 `jwt-public.pem`。

  - 为 jwt-user 创建 JWT 认证

  ```bash
  curl -X POST http://localhost:8001/consumers/jwt-user/jwt \
    -F rsa_public_key=@jwt-public.pem \  
    -F algorithm=RS256 \
    -F key=test-key
  ```

接下来同样用 [JWT debugger](https://jwt.io/) 或 [JWT CLI](https://github.com/mike-engel/jwt-cli) 生成 token，payload 里要有 iss: ${key}。拿到 token 后作为 Bearer 头访问 API 即可。

```bash
curl http://localhost:8000/jwt \
"Accept: application/json, */*" \
-H "Authorization:Bearer eyJhbGciOiJSUzI1NiIsInR5cGUiOiJKV1QifQ.eyJpYXQiOiIxNjA3MTc2NDM4IiwiZXhwIjoiMTYwNzE3Njk3OCIsImlzcyI6InRlc3Qta2V5In0.uLrS8T1j7nrEBYRZgZHYALDH2uhg81emRyv5K0bJi3eOwZj45I0ZXU9Lsz7MqryGwbHtP2dwyAQ9u9WXCuU-KSiwpL0L8fjBBjd339BwinQkevwjcr6QuFvch8hD0grYmS9z09jDJ7its0FrO-P0dIEvKhQ23ihADJiFMgTukgNyk3m76nNPkR22vQdJu-OATKVVp9iGpx7tRqZnPeCZAdlGrUJuiACPuqwxdrfithswnAbFg5AjzwB2K9BXiAl76PVYzo15s5KcPCQWJwJ0JY7MgMIEQ0xyifVBZLq__V3B5GgoWy-HEr9Bkd8Dc7ZkImxmJacpLUveWbuqXZ9JFg"
```

#### Auth0 认证

Auth0 认证与上面 RS256 步骤类似，但 `key` 需设为 Auth0 的 url，access_token 由 Auth0 生成。

- 下载 Auth0 认证文件

```bash
curl -o auth0.pem https://{COMPANYNAME}.{REGION-ID}.auth0.com/pem
```

有些用户无需 {REGION-ID}，需知道 Auth0 的 base url，不清楚可在 [这里](https://auth0.com/docs/tokens/manage-signing-keys#manage-your-signing-keys) 下载证书。

注意下载前需登录账号。

- 保存公钥

```bash
openssl x509 -pubkey -noout -in auth0.pem > auth0-pub.pem
```

当前目录下会有 `auth0-pub.pem`。

- 为 jwt-user 创建 JWT 认证

```bash
curl -X POST http://localhost:8001/consumers/jwt-user/jwt \
  -F rsa_public_key=@auth0-pub.pem \
  -F algorithm=RS256 \
  -F key=https://{COMPANYNAME}.auth0.com/
```

- 从 auth0 获取 Access Token

```bash
curl --request POST \
  --url https://{YOUR_AUTH0_URL}/oauth/token \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data grant_type=client_credentials \
  --data client_id=<APP_CLIENT_ID> \
  --data client_secret=<APP_CLIENT_SECRET> \
  --data audience=https://{YOUR_AUTH0_URL}/api/v2/
```

返回如下：

```json
{
  "access_token": "<YOUR_TOKEN>",
  "expires_in": 86400,
  "scope": "<SCOPES>",
  "token_type": "Bearer"
}
```

将 token 传给 Kong，即可访问 API 资源。

```bash
curl http://localhost:8000/jwt \
"Accept: application/json, */*" \
-H "Authorization: Bearer <YOUR_TOKEN>"
```

## 其他部署方式

### DBless 模式

将以下内容保存为 `kong.yaml`，在 DBless 部署中加载。示例中为 jwt-user 创建了三种 JWT 认证，实际可按需调整。

```yaml
_format_version: "2.1"
_transform: true

services:
- name: jwt-service
  url: https://httpbin.org/anything
  routes:
  - name: jwt-route
    paths:
    - /jwt

consumers:
- username: jwt-user
  jwt_secrets:
  - algorithm: RS256
    key: test-key
    rsa_public_key: |
      -----BEGIN PUBLIC KEY-----
      ...
      -----END PUBLIC KEY-----
    secret: Qrrg5r3pXyTrEmli67PiUiAheT9S4Fem
  - algorithm: HS256
    key: <YOUR_HS256_KEY>
    secret: <YOUR_HS256_SECRET>
  - algorithm: RS256
    key: https://{COMPANY}.auth0.com/
    rsa_public_key: |
      -----BEGIN PUBLIC KEY-----
      ...
      -----END PUBLIC KEY-----
    secret: 9VRPEid3GiK5rflY8Cf4wYwJAqyLth7U

plugins:
- name: jwt
  route: jwt-route
```

### Kubernetes Ingress Controller

:::note
请将 key 和 secret 替换为你自己的公钥。
:::

以下资源将被部署：

- Echo deployment
- Echo Service
- JWT 插件
- Consumer jwt-user
- Ingress 规则（使用 jwt 插件）
- 3 组 JWT 认证（HS256、RS256、Auth0）

保存为 `jwt.yaml`，用 `kubectl apply -f jwt.yaml` 应用。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: echo-pod
  template:
    metadata:
      labels:
        app: echo-pod
    spec:
      containers:
      - name: echoheaders
        image: k8s.gcr.io/echoserver:1.10
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: echo-service
spec:
  selector:
    app: echo-pod
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 8080
  type: LoadBalancer
---
apiVersion: configuration.konghq.com/v1
kind: KongConsumer
metadata:
  name: jwt-user
  annotations:
    kubernetes.io/ingress.class: "kong"
username: jwt-user
credentials:
  - jwt-key-rs256
  - jwt-key-auth0
  - jwt-key-hs256
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: proxy-to-echo
  annotations:
    konghq.com/plugins: jwt-auth
    konghq.com/strip-path: "true"
spec:
  ingressClassName: kong
  rules:
  - http:
      paths:
      - backend:
          service:
            name: echo-service
            port:
              number: 80
        path: /jwt
        pathType: Prefix
---
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: jwt-auth
plugin: jwt
---
apiVersion: v1
kind: Secret
metadata:
  name: jwt-key-rs256
type: Opaque
stringData:
  kongCredType: jwt
  key: test-issuer
  algorithm: RS256
  rsa_public_key: |
    -----BEGIN PUBLIC KEY-----
    ...
    -----END PUBLIC KEY-----
---
apiVersion: v1
kind: Secret
metadata:
  name: jwt-key-auth0
type: Opaque
stringData:
  kongCredType: jwt
  key: https://{COMPANY}.auth0.com/
  algorithm: RS256
  rsa_public_key: |
    -----BEGIN PUBLIC KEY-----
    ...
    -----END PUBLIC KEY-----
---
apiVersion: v1
kind: Secret
metadata:
  name: jwt-key-hs256
type: Opaque
stringData:
  kongCredType: jwt
  algorithm: HS256
  key: <YOUR_HS256_KEY>
  secret: <YOUR_HS256_SECRET>
```

今天就到这里，感谢阅读，我们下次见！

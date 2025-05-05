---
title: "Using the JWT Plugin in Kong Gateway"
date: 2023-05-22T00:33:31+09:00
draft: false
tags:
- Kong Gateway
- plugin
- JWT
---

(Translated from [https://tech.aufomm.com/how-to-use-jwt-plugin/](https://tech.aufomm.com/how-to-use-jwt-plugin/))

Kong has many authentication plugins. This time, I would like to talk about how to use the JWT Plugin.

## Usage Example

### Create a Service

```bash
curl -X POST http://localhost:8001/services \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, */*" \
  -d '{"name":"jwt-service","url":"https://httpbin.org/anything"}'
```

### Create a Route

```bash
curl -X POST http://localhost:8001/services/jwt-service/routes \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, */*" \
  -d '{"name":"jwt-route","paths":["/jwt"]}'
```

If you access the route with `curl 'http://localhost:8000/jwt' -i`, you should get `HTTP/1.1 200 OK`.

### Enable the JWT Plugin

:::note
This plugin can be enabled per Service or globally.
:::

```bash
curl --request POST \
  --url http://localhost:8001/plugins \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data name=jwt
```

If you access the above route again, you should get `HTTP/1.1 401 Unauthorized`.

### Create a Consumer

Create a consumer to hold JWT credentials.

```bash
curl --request POST \
  --url http://localhost:8001/consumers \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data username=jwt-user
```

### Create JWT Credentials

The JWT plugin supports five algorithms. The main difference is how the keys are shared. When using RS256, the generated keys are asymmetric. On the other hand, HS256 uses a symmetric key to sign the token. Below are demos for both HS256 and RS256. For differences between algorithms, see the [Auth0 documentation](https://community.auth0.com/t/rs256-vs-hs256-jwt-signing-algorithms/58609).

#### HS256

- Generate key and secret with Kong

```bash
curl -X POST http://localhost:8001/consumers/jwt-user/jwt
```

By default, Kong uses the `HS256` algorithm to generate the `Key` and `Secret`.

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

- Use your own key and secret

Generate two passwords with pwgen.

```bash
pwgen -sBv 32 2
Mt4RTRWJk9pfWJpgthP4sHhcqR4hFKzK J3NKsJgt79tcLRfLWwVMJvVnTFk7WskW
```

Use the first as `key` and the second as `secret`. You can create multiple key pairs for the same consumer.

```bash
curl --request POST \
  --url http://localhost:8001/consumers/jwt-user/jwt \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data key=Mt4RTRWJk9pfWJpgthP4sHhcqR4hFKzK \
  --data secret=J3NKsJgt79tcLRfLWwVMJvVnTFk7WskW
```

You should see the following:

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

Next, use [JWT debugger](https://jwt.io/) or [JWT CLI](https://github.com/mike-engel/jwt-cli) to create a token. Make sure the payload includes iss: ${key}. Once you have the token, pass it as the Authentication Bearer header to access the API again.

```bash
curl http://localhost:8000/jwt \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJNdDRSVFJXSms5cGZXSnBndGhQNHNIaGNxUjRoRkt6SyJ9.pCV1wm3VixWkZ_Nh24v4RSQjvYhpb5vJp_LeTRZnF2o"
```

#### RS256

- Generate authentication files yourself

  - Create private and public keys

  ```bash
  openssl genrsa -out jwt-private.pem 2048 2>/dev/null &&\
  openssl rsa -in jwt-private.pem -outform PEM -pubout -out jwt-public.pem 2>/dev/null &&\
  echo -e 'Your private key is \033[1;4mjwt-private.pem\033[0m and public key is 
  \033[1;4mjwt-public.pem\033[0m'
  ```

  After running the above, you should have `jwt-private.pem` and `jwt-public.pem` in the folder.

  - Create JWT credentials for jwt-user

  ```bash
  curl -X POST http://localhost:8001/consumers/jwt-user/jwt \
    -F rsa_public_key=@jwt-public.pem \  
    -F algorithm=RS256 \
    -F key=test-key
  ```

Next, as before, use [JWT debugger](https://jwt.io/) or [JWT CLI](https://github.com/mike-engel/jwt-cli) to create a token. Make sure the payload includes iss: ${key}. Once you have the token, pass it as the Authentication Bearer header to access the API again.

```bash
curl http://localhost:8000/jwt \
"Accept: application/json, */*" \
-H "Authorization:Bearer eyJhbGciOiJSUzI1NiIsInR5cGUiOiJKV1QifQ.eyJpYXQiOiIxNjA3MTc2NDM4IiwiZXhwIjoiMTYwNzE3Njk3OCIsImlzcyI6InRlc3Qta2V5In0.uLrS8T1j7nrEBYRZgZHYALDH2uhg81emRyv5K0bJi3eOwZj45I0ZXU9Lsz7MqryGwbHtP2dwyAQ9u9WXCuU-KSiwpL0L8fjBBjd339BwinQkevwjcr6QuFvch8hD0grYmS9z09jDJ7its0FrO-P0dIEvKhQ23ihADJiFMgTukgNyk3m76nNPkR22vQdJu-OATKVVp9iGpx7tRqZnPeCZAdlGrUJuiACPuqwxdrfithswnAbFg5AjzwB2K9BXiAl76PVYzo15s5KcPCQWJwJ0JY7MgMIEQ0xyifVBZLq__V3B5GgoWy-HEr9Bkd8Dc7ZkImxmJacpLUveWbuqXZ9JFg"
```

#### Authentication with Auth0

Authentication with Auth0 is similar to the RS256 steps above, but the `key` value must be set to the Auth0 URL, and the access_token is generated by Auth0.

- Download Auth0 authentication file

```bash
curl -o auth0.pem https://{COMPANYNAME}.{REGION-ID}.auth0.com/pem
```

Some users may not need to use {REGION-ID} in the URL. You need to know the base URL for Auth0, but if you don't, you can download the Auth0 certificate [here](https://auth0.com/docs/tokens/manage-signing-keys#manage-your-signing-keys).

Note: You need to log in to your account before downloading.

- Save the public key

```bash
openssl x509 -pubkey -noout -in auth0.pem > auth0-pub.pem
```

Now you should have `auth0-pub.pem` in your current folder.

- Create JWT credentials for jwt-user

```bash
curl -X POST http://localhost:8001/consumers/jwt-user/jwt \
  -F rsa_public_key=@auth0-pub.pem \
  -F algorithm=RS256 \
  -F key=https://{COMPANYNAME}.auth0.com/
```

- Get Access Token from auth0

```bash
curl --request POST \
  --url https://{YOUR_AUTH0_URL}/oauth/token \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data grant_type=client_credentials \
  --data client_id=<APP_CLIENT_ID> \
  --data client_secret=<APP_CLIENT_SECRET> \
  --data audience=https://{YOUR_AUTH0_URL}/api/v2/
```

You should get a response like this:

```json
{
  "access_token": "<YOUR_TOKEN>",
  "expires_in": 86400,
  "scope": "<SCOPES>",
  "token_type": "Bearer"
}
```

By passing the token to Kong, you should be able to access the API resource.

```bash
curl http://localhost:8000/jwt \
"Accept: application/json, */*" \
-H "Authorization: Bearer <YOUR_TOKEN>"
```

## Other Deployment Methods

### DBless Mode

Save the following to `kong.yaml` and load it into your DBless deployment configuration. In the example below, three types of JWT credentials are created for jwt-user. Change as needed for your requirements.

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
Change the key and secret values and replace with your own public key.
:::

The following will be deployed:

- Echo deployment
- Echo Service
- JWT Plugin
- Consumer jwt-user
- Ingress rule to use jwt plugin
- 3 JWT credentials for HS256, RS256, Auth0.

Save the following as `jwt.yaml` and apply with `kubectl apply -f jwt.yaml`.

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

That's all for today. Thank you for reading, see you next time.

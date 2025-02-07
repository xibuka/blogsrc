---
title: "Kong Gatewayの JWT Pluginを使ってみる"
date: 2023-05-22T00:33:31+09:00
draft: false
---

(https://tech.aufomm.com/how-to-use-jwt-plugin/ より翻訳)

Kongにはたくさんの認証プラグインがあります。今回はJWT Pluginの使い方についてお話したいと思います。

## 使用例

### サービスを作成

```
curl -X POST http://localhost:8001/services \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, */*" \
  -d '{"name":"jwt-service","url":"https://httpbin.org/anything"}'
```

### Routeを作成

```
curl -X POST http://localhost:8001/services/jwt-service/routes \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, */*" \
  -d '{"name":"jwt-route","paths":["/jwt"]}'
```

`curl 'http://localhost:8000/jwt' -i` でルートにアクセスすると、`HTTP/1.1 200 OK`となるはずです。

### JWT Pluginを有効

:::note
このプラグインは、Service単位またはグローバル全体に有効化することも可能です。
:::

```
curl --request POST \
  --url http://localhost:8001/plugins \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data name=jwt
```

上記のルートをもう一度アクセスすると、`HTTP/1.1 401 Unauthorized` となるはずです。

### consumerを作成
JWTの認証情報を持つためのconsumerを作成

```
curl --request POST \
  --url http://localhost:8001/consumers \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data username=jwt-user
```

### JWTの認証情報を作成
JWTプラグインは5つのアルゴリズムに対応しています。主な違いは、Keyの共有方法です。RS256を使用する場合、作成される鍵は非対称である。一方、HS256はトークンに署名するために対称鍵を使用します。以下、HS256とRS256のデモを行います。アルゴリズムの違いについては、[Auth0ドキュメント](https://community.auth0.com/t/rs256-vs-hs256-jwt-signing-algorithms/58609)を参照してください。

#### HS256

- KongでkeyとSecretを生成

```
curl -X POST http://localhost:8001/consumers/jwt-user/jwt
```

デフォルトでは、Kongは`HS256`アルゴリズムを使用して、`Key`と`Secret`を生成します。

```
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

- 自分のkeyとSecretを利用

pwgenでパスワードを二つ生成します。

```
pwgen -sBv 32 2
Mt4RTRWJk9pfWJpgthP4sHhcqR4hFKzK J3NKsJgt79tcLRfLWwVMJvVnTFk7WskW
```

1つ目を`key`、2つ目を`Secret`として使用します。同じConsumerで複数のキーペアを作成することができます。
```
curl --request POST \
  --url http://localhost:8001/consumers/jwt-user/jwt \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data key=Mt4RTRWJk9pfWJpgthP4sHhcqR4hFKzK \
  --data secret=J3NKsJgt79tcLRfLWwVMJvVnTFk7WskW
```

以下が表示されるはずです。
```
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

次は、[JWT debugger](https://jwt.io/)か[JWT CLI](https://github.com/mike-engel/jwt-cli)を使ってtokenを作成することができます。payloadにiss: ${key}が含まれていることを確認してください。tokenを取得したら、Authentication BearerヘッダとしてJWT tokenを渡すことで、再びAPIにアクセスできるようになるはずです。

```
curl http://localhost:8000/jwt \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJNdDRSVFJXSms5cGZXSnBndGhQNHNIaGNxUjRoRkt6SyJ9.pCV1wm3VixWkZ_Nh24v4RSQjvYhpb5vJp_LeTRZnF2o"
```

#### RS256

- 認証ファイルを自分で生成

  - プライベートkeyとパブリックKeyを作成

  ```
  openssl genrsa -out jwt-private.pem 2048 2>/dev/null &&\
  openssl rsa -in jwt-private.pem -outform PEM -pubout -out jwt-public.pem 2>/dev/null &&\
  echo -e 'Your private key is \033[1;4mjwt-private.pem\033[0m and public key is 
  \033[1;4mjwt-public.pem\033[0m'
  ```
  これで、上記コマンドを実行したフォルダに、`jwt-private.pem`と`jwt-public.pem`があるはずです。

  - jwt-userのためJWT認証を作成

  ```
  curl -X POST http://localhost:8001/consumers/jwt-user/jwt \
    -F rsa_public_key=@jwt-public.pem \  
    -F algorithm=RS256 \
    -F key=test-key
  ```

次は、さっきと同じく[JWT debugger](https://jwt.io/)か[JWT CLI](https://github.com/mike-engel/jwt-cli)を使ってtokenを作成することができます。payloadにiss: ${key}が含まれていることを確認してください。tokenを取得したら、Authentication BearerヘッダとしてJWT tokenを渡すことで、再びAPIにアクセスできるようになるはずです。

```
curl http://localhost:8000/jwt \
"Accept: application/json, */*" \
-H "Authorization:Bearer eyJhbGciOiJSUzI1NiIsInR5cGUiOiJKV1QifQ.eyJpYXQiOiIxNjA3MTc2NDM4IiwiZXhwIjoiMTYwNzE3Njk3OCIsImlzcyI6InRlc3Qta2V5In0.uLrS8T1j7nrEBYRZgZHYALDH2uhg81emRyv5K0bJi3eOwZj45I0ZXU9Lsz7MqryGwbHtP2dwyAQ9u9WXCuU-KSiwpL0L8fjBBjd339BwinQkevwjcr6QuFvch8hD0grYmS9z09jDJ7its0FrO-P0dIEvKhQ23ihADJiFMgTukgNyk3m76nNPkR22vQdJu-OATKVVp9iGpx7tRqZnPeCZAdlGrUJuiACPuqwxdrfithswnAbFg5AjzwB2K9BXiAl76PVYzo15s5KcPCQWJwJ0JY7MgMIEQ0xyifVBZLq__V3B5GgoWy-HEr9Bkd8Dc7ZkImxmJacpLUveWbuqXZ9JFg"
```

#### Auth0により認証

Auth0での認証は、上記のRS256の手順と同様ですが、`key`の値はAuth0のurlに設定する必要があり、access_tokenはAuth0が生成します。

- Auth0の認証ファイルをダウンロード

```
curl -o auth0.pem https://{COMPANYNAME}.{REGION-ID}.auth0.com/pem
```

URLに{REGION-ID}を使用する必要がないユーザーもいます。Auth0のベースURLを知っている必要がありますが、もし知らない場合は、Auth0証明書を[ここ](https://auth0.com/docs/tokens/manage-signing-keys#manage-your-signing-keys)からダウンロードできます。

なお、ダウンロードする前に、アカウントにログインする必要があります。

- 公開鍵の保存

```
openssl x509 -pubkey -noout -in auth0.pem > auth0-pub.pem
```

これで、現在のフォルダに`auth0-pub.pem`があるはずです。

- jwt-userのためJWT認証を作成

```
curl -X POST http://localhost:8001/consumers/jwt-user/jwt \
  -F rsa_public_key=@auth0-pub.pem \
  -F algorithm=RS256 \
  -F key=https://{COMPANYNAME}.auth0.com/
```

- auth0 からAccess _tokenを取得

```
curl --request POST \
  --url https://{YOUR_AUTH0_URL}/oauth/token \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data grant_type=client_credentials \
  --data client_id=<APP_CLIENT_ID> \
  --data client_secret=<APP_CLIENT_SECRET> \
  --data audience=https://{YOUR_AUTH0_URL}/api/v2/
```

以下のようなレスポンスになるはずです。

```
{
  "access_token": "<YOUR_TOKEN>",
  "expires_in": 86400,
  "scope": "<SCOPES>",
  "token_type": "Bearer"
}
```

Kongにトークンを渡すことで、apiリソースにアクセスできるようになるはずです。
```
curl http://localhost:8000/jwt \
"Accept: application/json, */*" \
-H "Authorization: Bearer <YOUR_TOKEN>"
```

## その他のデプロイ手法

### DBlessモード

以下の内容を `kong.yaml` に保存し、DBless のデプロイメント構成にロードしてください。以下の例では、jwt-userに対して3種類のJWTクレデンシャルを作成しています。要件に合わせて変更してください。

```
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
keyとSecretの値を変更し、ご自分のPublic keyに置き換えてください。
:::

以下の例では、こちらがデプロイされます。
- Echo deployment
- Echo Service
- JWT Plugin
- Consumer jwt-user
- Ingress rule to use jwt plugin
- 3 JWT credentials for HS256, RS256, Auth0.


下記を`jwt.yaml`に保存して、`kubectl apply -f jwt.yaml`で適用してください。

```
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

今日はこれで以上です。読んでくれてありがとう、また次回ね。

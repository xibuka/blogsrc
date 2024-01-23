---
title: "Kong OpenID Connectプラグインのその他の使用例"
date: 2024-01-23T22:55:37+09:00
draft: false
tags:
- Kong
- Kong Gateway
- OpenID
---

(https://tech.aufomm.com/kong-oidc-plugin-extra-use-cases/ より翻訳)

KongのOIDCプラグインはとてもパワフルで複雑なので（200近くのパラメーターがある...）、ユーザーがどのような設定の組み合わせが必要かを知っていれば、より多くのことができるようになる。今日の投稿では、このプラグインをよりうまく使うためのいくつかの使用例を紹介しよう。

なお、私はKong Gateway (Enterprise)の最新バージョン2.4.1.1を使用しています。

> 前提条件  
> - Kong Gateway (Enterprise)  
> - OIDCサーバーが稼動していること。(私の例ではKeycloak) もしKeycloakの使い方がわからない場合は、以前の投稿をご覧ください。  

## IDPトークンからデータを抽出しヘッダへの追加

IDPトークンからアップストリームヘッダーに値をマッピングしたい場合は、`config.upstream_headers_names`と`config.upstream_headers_claims`を使用できます。

例えば、JWTトークンのペイロードに以下のようなclaimがあるとします。

```json
{
  "payload": {
    "kong-test": "to-upstream"
  }
}
```

目的は、ヘッダー`kong-test`に`to-upstream`の値をマッピングし、アップストリームサーバーに送信することである。OIDCプラグインは以下のように設定できる。これはパスワードフローを使っている。

```
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

ユーザー名とパスワードを指定してapiエンドポイントを呼び出すと、アップストリームサーバーに送信されるリクエストに以下のヘッダーが表示されるはずです。

```
"Test-Kong": "to-upstream",
```

値がオブジェクトの場合。例えば、従業員の情報をヘッダーで上流に渡したい場合、それはbase64エンコードされる。

```
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

プラグインを有効にしてみましょう、

```
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

これで認証されると、アップストリームには以下のようなヘッダーが付くはずだ。

```
"X-Employee-Info": [
  "eyJuYW1lIjoibGkiLCJmYXZvdXJpdGVzIjp7ImJldmVyYWdlIjoiY29mZmVlIn0sImdyb3VwcyI6WyJkZWZhdWx0IiwiaXQiXX0="
]
```

## トークンを受け取る確認

時々、OIDCプラグインのセットアップに問題があるかもしれませんが、ログから必要な情報を見ることはできません。例えば、ログに kong failed to find the consumer for consumer mapping とありますが、token にはこの情報があるはずです。(これはリクエストにスコープを入れ忘れたときにclaimが追加されないために起こる可能性があります)。

このような状況でデバッグする最善の方法は、IDPから送り返されたトークンをチェックすることです。そのためには、`config.login_action=response`と`config.login_tokens=tokens`を設定する必要があります。

例えば

1. `authorization_code flow`でOIDCプラグインを有効にする。
    ```
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
1. ブラウザを使って `https://<kong_proxy>/<oidc_protected_route>` にアクセスする。
1. ログインすると、IDPからのトークンが表示されます。

## 必要なClaimsが複数

アプリケーションが、IDPから送信されたJWTトークンに特定の値を持つ特定のclaimを要求する場合、以下の4つのペアを使用してJWTトークンを検証できます。

- `config.groups_claim` and `config.groups_required`
- `config.scopes_claim` and `config.scopes_required`
- `config.roles_claim` and `config.roles_required`
- `config.audience_claim` and `config.audience_required`

パラメーターの名前は関係なく、どのClaimsに設定しても大丈夫。ただし、その使用にはいくつかのガイドラインがあります。

- 同時に最大4つのclaimを検証できます。
- or および and ロジックで同じclaimの複数の値を検証できます。
- claim名の配列/オブジェクトをトラバースできます。

例えば、私がJWTトークンで以下の`employee` claimsを取得するとしよう。

```
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

### claim配列全確認
好きな飲み物がコーヒーの従業員だけにアクセス権を与えたい場合、以下のようにOIDCプラグインを有効にすることができる。

```
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

ご覧のように、`"scopes_claim":["employee", "favorites", "beverage"]`を配列として設定し、`config.scopes_required=coffee`としている。KongはJWT claimを全部確認し、`beverage`が`coffee`と等しいかどうかを検証します。返されたJWTが`beverage=coffee`でない場合、ユーザーは`HTTP/1.1 403 Forbidden`を受け取ります。

### 特定のclaimについて複数の値を検証

- AND
`default`と`it`グループの両方に属しているユーザーにアクセス権を与えたい場合は、以下のようにOIDCプラグインを有効にします。

```
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
`default`と`it`グループのどっちかに属しているユーザーにアクセス権を与えたい場合は、以下のようにOIDCプラグインを有効にします。

```
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

ポイントは`config.scopes_required`です。配列のインデックスが`OR`、同じ配列のインデックスがスペースで区切られているのが`AND`になります。

## 認証エンドポイントに追加の引数を渡す

認可コードフロー(authorization code flow)を使用している場合、リダイレクトURL上の無関係なクエリ引数は削除されます。以下の設定で、認可エンドポイントのクエリ文字列に追加のクエリ引数を追加することができます。

### 変数値を追加

idpにクエリー引数を渡して、誰がサーバーにアクセスしているかを指定したいとします。例えば、`config.authorization_query_args_client`を設定することで、IDPにユーザ名や電子メールを渡すことができます。

```
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

その後、`https://<kong_proxy>/<protected_route>?username=admin`にアクセスすると、usernameが`admin`で追加されたのが見えるはず。

### 固定値を追加

固定値を追加したい場合は、`config.authorization_query_args_names`と`config.authorization_query_args_values`を使用して、複数の値のペアを追加することができます。

```
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

これで、`https://<kong_proxy>/<protected_route>`にアクセスすると、認証URLに`user=demo`と表示されるはずだ。

今日お伝えしたいことは以上です。次回はOIDCを使ったクライアント認証の方法を紹介する。
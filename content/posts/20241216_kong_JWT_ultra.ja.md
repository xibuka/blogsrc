---
title: "Kong を使用した JWT 検証の究極ガイド"
date: 2024-12-16T23:49:19+09:00
draft: false
tags:
- kong
- JWT
---

(https://tech.aufomm.com/the-ultimate-guide-of-using-jwt-with-kong/ より翻訳)

:::note
この記事は「究極の」ガイドとまでは言えないかもしれませんが、JWT 検証に使える公式の Kong プラグインを徹底的に解説することを目指しています。読み終えるころには、利用可能なオプションを全体的に理解し、それぞれのユースケースに最適なプラグインを選べるようになるはずです。
:::

## 背景

JSON Webトークン（JWT）は、Web開発に欠かせない要素であり、システム間で重要な情報を安全に伝える役割を果たします。その信頼性を確保するために、JWTの検証は欠かせないステップです。一方、KongのようなAPIゲートウェイは、特にOAuth 2.0やOIDC標準が普及する中で、組織のAPIアーキテクチャにおいて重要な位置を占めています。
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/aef17df0-a14a-ec52-90b6-dcac68149875.png)

この記事では、KongでJWTを検証するためのツールを詳しく解説し、現代のWeb開発環境でこのプロセスが果たす役割を探ります。

## JWTとは

:::note
すでにJWTについて理解している方は、どのプラグインを選ぶべきかの詳細を省略し、次のセクションから読み進めてください。
:::

JSON Web Token（JWT）は、JSON Web Signature（JWS）とJSON Web Encryption（JWE）の2つの形式で構成されています。本記事では、主にJWSの検証に焦点を当てています。JWEの検証について知りたい方は、[こちら](https://tech.aufomm.com/how-to-use-kong-jwe-decrypt-plugin/)の記事をご覧ください。

[RFC7515](https://www.rfc-editor.org/rfc/rfc7515.html)によると、JSON Web Signature（JWS）は、デジタル署名やメッセージ認証コード（MAC）で保護されたコンテンツを表現するためのJSONベースのデータ構造です。簡単に言えば、JWSは重要なメッセージを含む「署名付きの手紙」のようなものです。この手紙の信頼性を確保するためには、署名を検証する必要があります。

### アルゴリズム

JWSで使用される暗号アルゴリズムとその識別子は、別の仕様であるJSON Web Algorithms (JWA) [JWA](https://datatracker.ietf.org/doc/html/rfc7518)に定義されています。また、これらのアルゴリズムは、JWA仕様に基づいて作成されたIANAレジストリに記載されています。

JWSで使用される暗号アルゴリズムとその識別子は、別の仕様であるJSON Web Algorithms (JWA)仕様に記載されています。

通常、RS256やES256といった非対称アルゴリズムの使用が推奨されます。一方、HS256のような対称アルゴリズムの使用は推奨されていません。

### JWTのデータ構造

まず、JWTの構造を見てみましょう。以下に例を示します。

`
eyJhbGciOiJFUzI1NiIsImtpZCI6Imh1SEE3RDVaTUNKTWhLaVJIZVgwaGZSWG9fX1VBbEpCZ0FkTjhxb0MwMXcifQ.eyJpc3MiOiAiZm9tbSIsICJhdWQiOiAiand0LWRlbW8iLCAic3ViIjogImRlbW8tdXNlciIsICJpYXQiOiAxNjcyNDAzMzc4LCAiZXhwIjogMTY3MjQwMzY3OH0.bxkLGEjN4pXQQ6eymBO_DYl24NGu07FFR1ZXgmdFYHPGsNX10r6iyqDEtCHeXWs7Hsn-QIasV_i4Lw2nCHmlAA```
`

- JOSE header
  JOSEヘッダーには、通常、このJWSを保護するために使用されるハッシュアルゴリズム（alg）やキーID（kid）が記載されています。また、typ（タイプ）が含まれていることも一般的です

  ```json
  {
    "alg": "ES256",
    "kid": "huHA7D5ZMCJMhKiRHeX0hfRXo__UAlJBgAdN8qoC01w"
  }
  ```

- Payload
  ペイロードは、保護されて他の相手に渡されるメッセージです

  ```json
  {
    "iss": "fomm",
    "aud": "jwt-demo",
    "sub": "demo-user",
    "iat": 1672403378,
    "exp": 1672403678
  }
  ```

- Signature
  ユーザーは、JOSEヘッダーで定義されたアルゴリズムを使用して、保護されたヘッダーとペイロードの署名を計算し、署名が一致することを確認する必要があります

## JWT生成

JWTは非常に人気が高いため、さまざまなプログラミング言語向けのライブラリが利用可能です。また、KeycloakやAzureのようなOIDCプロバイダーを利用している場合、これらが自動的にJWTトークンを生成してくれます。このセクションでは、[jwt-cli](https://github.com/mike-engel/jwt-cli)とPythonの[jwcrypto](https://github.com/jpadilla/pyjwt/)ライブラリを使ってJWTを作成する方法を紹介します。

### RSA鍵ペアの生成

ここでは、opensslを使用して、トークンの署名用にRSAの秘密鍵を生成し、その検証用に公開鍵をエクスポートします。

```bash
openssl genpkey \
  -algorithm RSA \
  -pkeyopt rsa_keygen_bits:2048 \
  -outform pem -out rsa-private.pem 2>/dev/null

openssl pkey -pubout \
  -in rsa-private.pem \
  -out rsa-public.pem
```

### JWT CLI

:::note
nixがインストールされている場合は、`nix shell nixpkgs#jwt-cli`コマンドを使用してjwt-cliを利用できます。それ以外の場合は、公式の[Gitリポジトリ](https://github.com/mike-engel/jwt-cli)を参照してください。
:::

#### kid

[RFC 7515 section 4.1.4](https://datatracker.ietf.org/doc/html/rfc7515#section-4.1.4)によると、kid（キーID）の値の構造は特に指定されていません。その値は大文字と小文字を区別する文字列でなければなりません。このヘッダー項目の使用は任意です。しかし、ほとんどの場合、JOSEヘッダーにkidを含めることをお勧めします。これにより、受信者がJWK内のどの公開鍵を使用してトークンを検証すべきかを特定しやすくなります。

今回は、特定の公開鍵に関連付けられるように、ツールを使用してkidを生成します。

```bash
cat rsa-public.pem \
  | docker run --rm -i danedmunds/pem-to-jwk:latest --jwks-out \
  | jq -r '.keys[].kid' \
  | read JWT_KID
```

#### JWT 生成

次に、簡単なペイロードを使用して以下のようにJWTを生成します。

```bash
jwt encode \
  --alg RS256 \
  --exp=300s \
  --kid $JWT_KID \
  --iss fomm-jwt-cli \
  --secret @rsa-private.pem \
  '{"username":"fomm","roles":["demo"]}'

```

#### JWT 検証

RSAの秘密鍵を使用してトークンに署名しているため、その公開鍵を使って検証を行う必要があります。jwt-cliを使用する場合、以下のコマンドで検証できます。

```bash
jwt decode --secret @rsa-public.pem --alg RS256 <JWT>
```

出力

```bash
jwt decode --secret @rsa-public.pem --alg RS256 eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IkNfdTNJemNpSERKWTZ6TkdSeXJZN2prZjZrVWJMRFhEZ0M5TFlEeEtHUXMifQ.eyJleHAiOjE3MzM3MjQyMDAsImlhdCI6MTczMzcyMzkwMCwiaXNzIjoiZm9tbS1qd3QtY2xpIiwicm9sZXMiOlsiZGVtbyJdLCJ1c2VybmFtZSI6IldlbmhhbiJ9.vgVmu3OZXOyyIlmf6sEgsXbWZO88g3a_B9epFIMnFHU0uXhGCvUMiYUsWP8WzfOlWzacJhDsl9MHmQLySXn7IYHSVNBpIQUE-u4FdtKXNIMtvOFNTVZR9TI_ZXBlyvM6wm1wBq-06gwbiA8giGsG4n8Krc-qA9otLEFVCDUP6LtgxoJN_KAHSqEz3vERYEEcXGQeRNBYA6E3x_BzQGRV-royCQk8v-c6x42UQtkcHp1eVphAXTaMOlt-6nsP-nZvkOj1kAk1CbwiehbViDKIb2rJKhWu_aCLGZY0N-E7m6kU_gul9YUmzJqH5DtoAjum3kP3-1tZQk4rlsc7mzMVOw

Token header
------------
{
  "typ": "JWT",
  "alg": "RS256",
  "kid": "C_u3IzciHDJY6zNGRyrY7jkf6kUbLDXDgC9LYDxKGQs"
}

Token claims
------------
{
  "exp": 1733724200,
  "iat": 1733723900,
  "iss": "fomm-jwt-cli",
  "roles": [
    "demo"
  ],
  "username": "Wenhan"
}
```

### Python

`PyJWT`は、以下のコマンドでpipを使ってインストールできます：

```bash
pip install PyJWT
```

私は`nix develop`を使用する方を好みます。nixがインストールされている場合、以下の内容を`flake.nix`に保存してください。その後、次のコマンドを実行して環境をセットアップできます：

```bash
nix develop -c $SHELL
```

```python
{
  description = "Example Python development environment for Zero to Nix";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };
  outputs = {
    self,
    nixpkgs,
  }: let
    # Systems supported
    allSystems = [
      "x86_64-linux" # 64-bit Intel/AMD Linux
      "aarch64-linux" # 64-bit ARM Linux
      "x86_64-darwin" # 64-bit Intel macOS
      "aarch64-darwin" # 64-bit ARM macOS
    ];
    forAllSystems = f:
      nixpkgs.lib.genAttrs allSystems (system:
        f {
          pkgs = import nixpkgs {inherit system;};
        });
  in {
    # Development environment output
    devShells = forAllSystems ({pkgs}: {
      default = let
        # Use Python 3.11
        python = pkgs.python311;
      in
        pkgs.mkShell {
          # The Nix packages provided in the environment
          packages = [
            # Python plus helper tools
            (python.withPackages (ps:
              with ps; [
                jwcrypto
              ]))
          ];
        };
    });
  };
}

```

#### JWT 生成

次に、以下の内容をjwt.pyとして保存します。その後、`python jwt.py`を実行することで、トークンを作成できるようになります。

```python
from jwcrypto import jwk, jwt
from datetime import datetime

def generate_jwt(private_key_path, algorithm):
  timestamp = int(datetime.now().timestamp())
  payload = {
    "iat": timestamp,
    "exp": timestamp + 300,
    "iss": "fomm-jwtcrypto",
    "username": "fomm",
    "roles": ["demo"],
  }
  with open(private_key_path, "rb") as pemfile:
    private_key = jwk.JWK.from_pem(pemfile.read())
    jwt_token = jwt.JWT(header={"alg": algorithm, "kid": private_key.thumbprint(), "typ":"JWT"}, claims=payload)
    jwt_token.make_signed_token(private_key)
  return jwt_token.serialize()

def main():
  private_key_path = "rsa-private.pem"
  jwt_algorithm = "RS256"
  jwt_token = generate_jwt(private_key_path, jwt_algorithm)
  print(jwt_token)

if __name__ == "__main__":
  main()
```

#### JWT 検証

`jwcrypto`ライブラリを使用した検証は非常に簡単です。以下に使用できるサンプルを示します。

```python
from jwcrypto import jwk, jwt

def validate_jwt(public_key_path, jwt_token):
    with open(public_key_path, "rb") as pemfile:
        public_key = jwk.JWK.from_pem(pemfile.read())
        verified_token = jwt.JWT(jwt=jwt_token, key=public_key)
        try:
            verified_token.validate(public_key)
            return True
        except Exception as e:
            return False

def main():
    public_key_path = "rsa-public.pem"
    jwt_token = input("Enter JWT token: ")
    is_valid = validate_jwt(public_key_path, jwt_token)
    if is_valid:
        print("Token is valid.")
    else:
        print("Token is invalid.")

if __name__ == "__main__":
    main()
```

## どのプラグインを使用すべきか？

JWTの検証には、Kongの公式プラグインが3つ提供されています：

1. JWTプラグイン
1. JWT Signerプラグイン（エンタープライズ版）
1. OpenID Connect（OIDC）プラグイン（エンタープライズ版）

エンタープライズライセンスがない場合は、オープンソース版のJWTプラグインのみ使用可能です。このプラグインを実装するには、各コンシューマーごとに個別の`jwt_secrets`を作成する必要があります。複数のコンシューマーに同じRSA公開鍵を関連付けたい場合は、すべての`jwt_secrets`内のキー値が一意であることを確認してください。詳しくは、[こちら](https://tech.aufomm.com/how-to-use-jwt-plugin/)のブログ記事をご覧ください。

エンタープライズ版で全てのプラグインが利用可能な場合、以下のことを考えてみてください：

- JWTはどのように生成されますか？
  - IDP（Identity Provider）によりトークンを生成する場合、OIDCプラグインまたはJWT Signerプラグイン
- 複数のIDPから発行されたJWTを検証する必要がありますか？
  - OIDCプラグインは、複数のJWKから公開鍵の取得と自動ローテーションをサポートするので、JWT検証に利用可能
- インターネットアクセスがないUpstream APIサービスがある場合は？
  - JWT Signerプラグインを使えば、トークンを再署名できます。upstream サーバーはKongの公開鍵のみを信頼すれば良いため、IDPのJWK取得が不要
- JWT claimsを検証する必要がありますか？
  - スコープの検証が必要な場合、OIDCプラグインが最適です。同時に最大4つのクレームが検証可能
- token claim を読み取り、ヘッダーとして上流や下流に渡す必要がありますか？
  - この場合は、OIDCプラグインを使用する必要がある
- 異なるIDPから発行された2つのトークンを同時に検証する必要がありますか？
  - 例えば、access tokenとchannel tokenのように2つのトークンを検証する場合、JWT Signerプラグインが適切
- アクセス制御のためにグループマッピングが必要ですか？
  - すべてのプラグインでコンシューマーマッピングが可能
  - ただし、IDPで開発者を管理したい場合、OIDCプラグインを使用することでトークンクレームに基づいた仮想認証情報を作成できます。この仮想認証情報は、レート制限やアクセス制御に活用可能

まだどのプラグインを選ぶべきか分からない場合は、まずOIDCプラグインから始めることをおすすめします。OIDCプラグインはKongの中で最も高度な認証プラグインであり、他の2つのプラグインよりも多くの機能を提供します。例えば、鍵のローテーション再検出、仮想認証情報、スコープ検証などです。

「OIDCプラグインを強く推奨しているけれど、OpenID Connectプロバイダーを使っていない場合でも使えるの？」と疑問に思うかもしれません。答えはYESです。このプロセスについてもガイドします。

## OIDC JWT validation

仕組みは非常にシンプルです。OIDCプラグインはJWKを取得し、これらの公開鍵をキャッシュに保存してJWTの検証に使用します。IDPが鍵をローテーションし、新しい鍵でトークンに署名した場合、OIDCプラグインはJWKエンドポイントから公開鍵を再取得します。

Kongが保持している公開鍵を確認するには、`<admin_api>/openid-connect/issuers`にアクセスしてください：

:::note
JWT Signerは似たような仕組みで動作しますが、1つのURLからのみJWKを取得できる点と、トークンを再署名する点が異なります。
詳細については、[こちら](https://tech.aufomm.com/how-to-use-jwt-signer-plugin/)のブログ記事をご覧ください。
:::

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/1f4732a6-54b7-917e-c016-856630a24694.png)

### JWKs 生成

公開鍵JWKを生成するために、[danedmunds/pem-to-jwk](https://github.com/danedmunds/pem-to-jwk)のDockerイメージを使用します。

```bash
cat rsa-public.pem \
  | docker run -i danedmunds/pem-to-jwk:latest --jwks-out \
  | jq '.keys[] += {alg:"RS256"}' \
  > jwks.json
```

### docker network 生成

コンテナは同じDockerネットワークkong-net内で実行します。

```bash
docker network create kong-net
```

### JWKs ホスティング

次に、これらの鍵をホストするためにjson-serverを使用します。

```bash
docker run --rm \
  --detach --name jwk \
  --network kong-net \
  -p "3000:3000" \
  --mount type=bind,src="$(pwd)"/jwks.json,dst=/jwk.json \
  williamyeh/json-server --watch /jwk.json
```

### Kong EE起動

デモ用にKongをDBlessモードでデプロイします。Kong Enterpriseの有効なライセンスが`KONG_LICENSE_DATA`という環境変数に保存されていると仮定します。以下のコマンドで、Kong Enterprise 3.5をDBlessモードで起動できます。

```bash
docker run --rm --detach --name kong \
  --network kong-net \
  -p "8000-8001:8000-8001" \
  -e "KONG_ADMIN_LISTEN=0.0.0.0:8001" \
  -e "KONG_PROXY_LISTEN=0.0.0.0:8000" \
  -e "KONG_DATABASE=off" \
  -e "KONG_LICENSE_DATA=$KONG_LICENSE_DATA" \
  kong/kong-gateway:3.5
```

### Kong 設定内容の準備

以下の内容を `/tmp/kong.yaml`に保存しましょう

```yaml
_format_version: "3.0"
routes:
- name: upstream-route
  paths:
  - /upstream
  plugins:
  - config:
      echo: true
      status_code: 200
    name: request-termination
services:
- name: test-svc
  host: localhost
  path: /upstream
  port: 8000
  protocol: http
  routes:
  - name: test-route
    paths:
    - /test
    plugins:
    - config:
        auth_methods:
        - bearer
        extra_jwks_uris:
        - http://jwk:3000/db
        issuer: http://jwk:3000/db
        issuers_allowed:
        - fomm-jwt-cli
        - fomm-jwtcrypto
      name: openid-connect
```

上記の設定で行うことは以下の通りです。

- [request termination](https://docs.konghq.com/hub/kong-inc/request-termination/#main)プラグインを使用し、200レスポンスを返し、リクエストをそのままエコーバックします。
- すべてのJWKは`config.extra_jwks_uris`に配置し、OIDCプラグインが鍵を取得できるようにします。
- すべてのIssuer (Pythonとjwt-cliコマンド) は`config.issuers_allowed`にリストされています。OIDCプラグインはデフォルトでIssuerを検証します。

最後に、このファイルをKongの`/config`エンドポイントにプッシュできます。

```bash
curl --request POST \
  --url http://localhost:8001/config \
  -F config=@/tmp/kong.yaml
```

### JWT 検証

これで準備が整いましたので、セットアップをテストしてみましょう。最初に上記の手順に従ってJWTを生成してください。簡単に参照できるように、以下のコマンドでJWTを`token`変数に格納します。

```bash
cat rsa-public.pem \
  | docker run -i danedmunds/pem-to-jwk:latest --jwks-out \
  | jq -r '.keys[].kid' \
  | read JWT_KID

jwt encode \
  --alg RS256 \
  --exp=300s \
  --kid $JWT_KID \
  --iss fomm-jwt-cli \
  --secret @rsa-private.pem \
  '{"username":"fomm","roles":["demo"]}' \
  | read token
```

次に、このトークンを`authorization bearer token`として使用してエンドポイントを呼び出すと、`200`レスポンスが返されるはずです。

```bash
curl --request GET -i \
  --url http://localhost:8000/test \
  --header "authorization:  Bearer $token"
```

今日はここまでにします。適切なプラグインを選ぶための参考になれば幸いです。
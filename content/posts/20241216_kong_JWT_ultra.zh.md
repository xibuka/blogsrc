---
title: "使用 Kong 进行 JWT 验证的终极指南"
date: 2024-12-16T23:49:19+09:00
draft: false
tags:
- kong
- JWT
---

（翻译自 `https://tech.aufomm.com/the-ultimate-guide-of-using-jwt-with-kong/`）

:::note
本文也许还称不上"终极"指南，但目标是彻底讲解 Kong 官方可用的 JWT 验证插件。读完后，你应该能全面理解各种选项，并能为自己的场景选择最合适的插件。
:::

## 背景

JSON Web Token（JWT）是 Web 开发中不可或缺的要素，是系统间安全传递重要信息的手段。为了保证其可靠性，JWT 验证是必不可少的步骤。同时，Kong 这样的 API 网关，尤其在 OAuth 2.0 和 OIDC 标准普及的今天，在企业 API 架构中扮演着关键角色。
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/aef17df0-a14a-ec52-90b6-dcac68149875.png)

本文将详细讲解 Kong 中用于 JWT 验证的工具，并探讨这一流程在现代 Web 开发中的作用。

## 什么是 JWT？

:::note
如果你已经了解 JWT，可以跳过插件选择细节，直接阅读后续章节。
:::

JSON Web Token（JWT）有两种格式：JSON Web Signature（JWS）和 JSON Web Encryption（JWE）。本文主要聚焦于 JWS 的验证。如需了解 JWE 验证，请参见[这里](https://tech.aufomm.com/how-to-use-kong-jwe-decrypt-plugin/)。

根据 [RFC7515](https://www.rfc-editor.org/rfc/rfc7515.html)，JSON Web Signature（JWS）是一种基于 JSON 的数据结构，用于表达被数字签名或消息认证码（MAC）保护的内容。简单来说，JWS 就像一封"带签名的信"，里面包含重要信息。要确保其可信性，必须验证签名。

### 算法

JWS 所用的加密算法及其标识符定义在 JSON Web Algorithms (JWA) [JWA](https://datatracker.ietf.org/doc/html/rfc7518) 规范中，并在 IANA 注册表中列出。

推荐优先使用非对称算法（如 RS256、ES256），不推荐使用对称算法（如 HS256）。

### JWT 的数据结构

先看一个 JWT 的结构示例：

`
eyJhbGciOiJFUzI1NiIsImtpZCI6Imh1SEE3RDVaTUNKTWhLaVJIZVgwaGZSWG9fX1VBbEpCZ0FkTjhxb0MwMXcifQ.eyJpc3MiOiAiZm9tbSIsICJhdWQiOiAiand0LWRlbW8iLCAic3ViIjogImRlbW8tdXNlciIsICJpYXQiOiAxNjcyNDAzMzc4LCAiZXhwIjogMTY3MjQwMzY3OH0.bxkLGEjN4pXQQ6eymBO_DYl24NGu07FFR1ZXgmdFYHPGsNX10r6iyqDEtCHeXWs7Hsn-QIasV_i4Lw2nCHmlAA```
`

- JOSE header
  JOSE 头通常包含用于保护该 JWS 的哈希算法（alg）和密钥 ID（kid），也常见 typ（类型）。

  ```json
  {
    "alg": "ES256",
    "kid": "huHA7D5ZMCJMhKiRHeX0hfRXo__UAlJBgAdN8qoC01w"
  }
  ```

- Payload
  Payload 是被保护并传递给对方的消息。

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
  用户需用 JOSE 头中指定的算法对头和载荷进行签名，并验证签名是否一致。

## JWT 生成

JWT 非常流行，几乎所有主流编程语言都有相关库。如果你用 Keycloak、Azure 等 OIDC 提供方，JWT 令牌会自动生成。本节介绍如何用 [jwt-cli](https://github.com/mike-engel/jwt-cli) 和 Python 的 [jwcrypto](https://github.com/jpadilla/pyjwt/) 库生成 JWT。

### 生成 RSA 密钥对

这里用 openssl 生成用于签名的 RSA 私钥，并导出公钥用于验证。

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
如果你已安装 nix，可用 `nix shell nixpkgs#jwt-cli` 直接用 jwt-cli，否则请参考官方 [Git 仓库](https://github.com/mike-engel/jwt-cli)。
:::

#### kid

根据 [RFC 7515 section 4.1.4](https://datatracker.ietf.org/doc/html/rfc7515#section-4.1.4)，kid（密钥 ID）值的结构没有强制要求，只需区分大小写即可。该头字段可选，但强烈建议在 JOSE 头中包含 kid，便于接收方确定用哪个 JWK 公钥验证。

这里用工具为特定公钥生成 kid。

```bash
cat rsa-public.pem \
  | docker run --rm -i danedmunds/pem-to-jwk:latest --jwks-out \
  | jq -r '.keys[].kid' \
  | read JWT_KID
```

#### JWT 生成

用简单 payload 生成 JWT：

```bash
jwt encode \
  --alg RS256 \
  --exp=300s \
  --kid $JWT_KID \
  --iss fomm-jwt-cli \
  --secret @rsa-private.pem \
  '{"username":"fomm","roles":["demo"]}'

```

#### JWT 验证

用 RSA 私钥签名后，需用公钥验证。用 jwt-cli 验证如下：

```bash
jwt decode --secret @rsa-public.pem --alg RS256 <JWT>
```

输出：

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

用 pip 安装 `PyJWT`：

```bash
pip install PyJWT
```

我更喜欢用 `nix develop`。如果你已安装 nix，可将以下内容保存为 `flake.nix`，然后运行下述命令进入环境：

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

将以下内容保存为 jwt.py，运行 `python jwt.py` 即可生成 token。

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

#### JWT 验证

用 `jwcrypto` 库验证非常简单，示例代码如下：

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

## 应该用哪个插件？

Kong 官方提供三种 JWT 验证插件：

1. JWT 插件
1. JWT Signer 插件（企业版）
1. OpenID Connect（OIDC）插件（企业版）

如果没有企业版授权，只能用开源 JWT 插件。要用该插件，需为每个 consumer 创建独立的 `jwt_secrets`。如需将同一 RSA 公钥关联到多个 consumer，需确保所有 `jwt_secrets` 的 key 值唯一。详见[这篇博客](https://tech.aufomm.com/how-to-use-jwt-plugin/)。

如果企业版所有插件都可用，建议考虑：

- JWT 如何生成？
  - 若由 IDP（身份提供方）生成，推荐用 OIDC 插件或 JWT Signer 插件
- 是否需验证多个 IDP 签发的 JWT？
  - OIDC 插件支持从多个 JWK 获取公钥并自动轮换，适合 JWT 验证
- 是否有无法访问互联网的上游 API 服务？
  - JWT Signer 插件可对 token 重新签名，上游只需信任 Kong 公钥，无需从 IDP 获取 JWK
- 是否需验证 JWT claims？
  - 若需验证 scope，OIDC 插件最合适，可同时验证最多 4 个 claim
- 是否需读取 token claim 并作为 header 传递？
  - 这种场景用 OIDC 插件
- 是否需同时验证来自不同 IDP 的两个 token？
  - 如需同时验证 access token 和 channel token，推荐 JWT Signer 插件
- 是否需做分组映射实现访问控制？
  - 所有插件都支持 consumer 映射
  - 若希望在 IDP 管理开发者，OIDC 插件可基于 claim 创建虚拟凭证，用于限流和访问控制

如果还不确定选哪个插件，建议优先试用 OIDC 插件。它是 Kong 最先进的认证插件，功能远超另外两种，如密钥轮换检测、虚拟凭证、scope 验证等。

你可能会问："强烈推荐 OIDC 插件，但没用 OpenID Connect 提供方也能用吗？"答案是 YES，本文也会介绍相关流程。

## OIDC JWT 验证

原理很简单。OIDC 插件会获取 JWK 并缓存公钥，用于 JWT 验证。如果 IDP 轮换密钥并用新密钥签名，OIDC 插件会自动从 JWK 端点获取新公钥。

要查看 Kong 当前持有的公钥，可访问 `<admin_api>/openid-connect/issuers`：

:::note
JWT Signer 插件机制类似，但只能从一个 URL 获取 JWK，并会对 token 重新签名。详见[这篇博客](https://tech.aufomm.com/how-to-use-jwt-signer-plugin/)。
:::

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/1f4732a6-54b7-917e-c016-856630a24694.png)

### JWKs 生成

用 [danedmunds/pem-to-jwk](https://github.com/danedmunds/pem-to-jwk) Docker 镜像生成公钥 JWK：

```bash
cat rsa-public.pem \
  | docker run -i danedmunds/pem-to-jwk:latest --jwks-out \
  | jq '.keys[] += {alg:"RS256"}' \
  > jwks.json
```

### 创建 docker network

让容器运行在同一 docker 网络 kong-net：

```bash
docker network create kong-net
```

### JWKs 托管

用 json-server 托管这些密钥：

```bash
docker run --rm \
  --detach --name jwk \
  --network kong-net \
  -p "3000:3000" \
  --mount type=bind,src="$(pwd)"/jwks.json,dst=/jwk.json \
  williamyeh/json-server --watch /jwk.json
```

### 启动 Kong EE

演示用 DBless 模式部署 Kong。假设企业版 license 已保存在 `KONG_LICENSE_DATA` 环境变量中，以下命令可启动 Kong Enterprise 3.5：

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

### Kong 配置准备

将以下内容保存为 `/tmp/kong.yaml`：

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

上述配置说明：

- 用 [request termination](https://docs.konghq.com/hub/kong-inc/request-termination/#main) 插件返回 200 响应并回显请求
- 所有 JWK 放在 `config.extra_jwks_uris`，OIDC 插件可获取密钥
- 所有 issuer（Python 和 jwt-cli）都列在 `config.issuers_allowed`，OIDC 插件默认会校验 issuer

最后，将该文件推送到 Kong 的 `/config` 端点：

```bash
curl --request POST \
  --url http://localhost:8001/config \
  -F config=@/tmp/kong.yaml
```

### JWT 验证

一切准备就绪后，按上述方法生成 JWT。可用如下命令将 JWT 存入 `token` 变量：

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

然后用该 token 作为 `authorization bearer token` 调用接口，应返回 `200` 响应：

```bash
curl --request GET -i \
  --url http://localhost:8000/test \
  --header "authorization:  Bearer $token"
```

今天就到这里，希望本文能帮你选对插件。

---
title: "用 Mozila SOPS+age 实现 Kong Gateway 安全部署"
date: 2023-03-08T16:41:18+09:00
draft: false
tags:
- Kong
- Security
---
## 背景

在部署 Kong Gateway 时，常常有一些不希望以明文保存的数据库连接信息等敏感数据。为了解决这个问题，Kong Secret Manager 被开发出来，结合 AWS Secrets Manager 等第三方服务可以很好地解决。但有些环境无法连接外部安全服务，这时就无法使用这些功能。这里介绍如何利用 Mozila 开发的 SOPS 加密工具和 Github Action 的 CI/CD workflow，将配置文件平时加密存储，仅在部署时解密并安装 Kong GW。

## 事前准备

在构建 CI/CD workflow 之前，先在本地环境试试加密和解密。需要安装以下工具：

1. [age](https://github.com/FiloSottile/age/releases)
2. [sops](https://github.com/mozilla/sops/releases)

SOPS 是非常流行的加解密工具，支持 PGP、age、Google Cloud KMS、Azure Key Vault、Hashicorp Vault 等。本文因尽量不依赖云服务，选择了 age。

工具安装好后，试试 `age-keygen --help`：

```bash
$ age-keygen --help
Usage:
    age-keygen [-o OUTPUT]
    age-keygen -y [-o OUTPUT] [INPUT]

Options:
    -o, --output OUTPUT       Write the result to the file at path OUTPUT.
    -y                        Convert an identity file to a recipients file.
```

确认没问题后，生成密钥：

## 生成 key

```bash
$ age-keygen -o sops-key.txt
Public key: age1hhpnj4ylj5z7qwaek0ncrq882ygmvnv4unup78u3djgmlezrmgkqshyatc

$ cat sops-key.txt
# created: 2023-03-08T06:07:28Z
# public key: age1hhpnj4ylj5z7qwaek0ncrq882ygmvnv4unup78u3djgmlezrmgkqshyatc
AGE-SECRET-KEY-1UHJNXS6RKYWA72RVED0ERGZVQ98N6MDFV6Y3CSPPN9JKLKSRH9GSQRLFAE
```

`sops-key.txt` 文件中包含两种 key。Public key 用于加密，Private key 用于解密。

## 配置文件加密

为了更方便地使用 SOPS，可以创建一个 `.sops.yaml` 配置文件。这样就不用每次命令行指定 key。age 字段填写刚才生成的 Public key，encrypted_regex 用于指定哪些字段需要加密。

``` yaml
creation_rules:
  - encrypted_regex: '^(env|admin|proxy|enterprise|manager|portal|portalapi|postgresql)$'
    age: age1hhpnj4ylj5z7qwaek0ncrq882ygmvnv4unup78u3djgmlezrmgkqshyatc
```

有了上述配置后，可以用如下命令加密 Kong GW 部署文件：

``` bash
$ sops -e -i values.yaml
$ head values.yaml
image:
    repository: kong/kong-gateway
    tag: "3.1"
env:
    prefix: ENC[AES256_GCM,data:2AFF90x0Q3Ej9cMDiw==,iv:o/jBUcZIypUEioKk0Fd4uheBrCOlUOL4RQYExOW696E=,tag:LoIjejClr7lh37Rq9YeKDw==,type:str]
    log_level: ENC[AES256_GCM,data:ZhYxI6A=,iv:oZJ8E/MocmOonUPD2FY6BLaXPuj4TBl//0fqTmOY0Xg=,tag:46p/kxlNSctmOGFupQSnOQ==,type:str]
    database: ENC[AES256_GCM,data:3L8H1aqImEc=,iv:9iF+73VeFWbsmHqW1yKBCgwMpO3us8pTWwSWmNaCl80=,tag:icNvo+EvoYnxiAGdjxzPqw==,type:str]
    proxy_url: ENC[AES256_GCM,data:89WLCtCUglsyZQdsns1Lj6O/CI6YtCc8wXdX9EIJCGNwzmjB8v8=,iv:HUFPH8bgG62UvAeQATh/0GprR8zOgLBGmvcYbON4B00=,tag:Q1l7E8l5xClp52KSEz+MNQ==,type:str]
    admin_gui_url: ENC[AES256_GCM,data:Xun4V7eliBRlmfn8v3CVFwxMjRumh+REwmPgCDbWwrPhjSQMXkn6qQ==,iv:8zH3GjO35ycpAsuOgDB+UKNAc19zSee72z2UlrdZ+Js=,tag:U4IEK5Nef6h59vbHyM0aSA==,type:str]
    admin_api_uri: ENC[AES256_GCM,data:52j0JgFNldx5Qytsqav9nSLLLEUzR7+KsNo8aTsjbS2IyTM1R00=,iv:0RkBMi8k/XhuEzGSRpIQ9VQGbcUOTcb+o/KUVJ5LSYk=,tag:m5o89fI+GCKxD7TcLf5Nqg==,type:str]
```

`image` 字段未被加密，因为不在 encrypted_regex 范围内。

## 配置文件解密

解密时，先把 Private key 复制到 `.config/sops/age/keys.txt`。这是默认路径，执行 sops 命令时无需再指定 Private key。
设置好后，用如下命令解密文件：

``` bash
$ sops -d -i values.yaml
$ head values.yaml
image:
    repository: kong/kong-gateway
    tag: "3.1"
env:
    prefix: /kong_prefix/
    log_level: debug
    database: postgres
    proxy_url: http://www.kongtest.net:8000
    admin_gui_url: http://www.kongtest.net:8002
    admin_api_uri: http://www.kongtest.net:8001
```

## CI/CD workflow

接下来，将上述内容集成到 Kong Gateway 的 CI/CD 部署流程中，就可以在不暴露明文配置的情况下完成部署。解密后的配置文件只在 CI/CD workflow 内存在，流程结束后会被删除。

流程如下图：

![workflow](https://raw.githubusercontent.com/robincher/kong-mozilla-sops-demo/master/assets/context.png)

1. 生成 Public/Private key
1. 配置文件加密
1. 提交加密配置文件
1. GitHub Action
    4-1. 安装工具
    4-2. 获取 Private key
    4-3. 解密配置文件
    4-4. 用 helm 部署 Kong Gateway

1-3 步都可在本地完成。需要注意 4-2 获取 Private key，建议用 Github Action 的 Secrets 功能提前注册，这样 workflow 里可直接引用，不会泄露明文。Public/Private 必须配对，否则解密会报错。

CI/CD workflow 示例可参考 [main.yml](https://raw.githubusercontent.com/robincher/kong-mozilla-sops-demo/master/.github/workflows/main.yaml)。提交加密配置文件后，Kong Gateway 就能顺利安装。

## 总结

通过 CI/CD，可以在部署 Kong Gateway 后自动创建 service、Route、备份和恢复配置等。如果配置中有敏感信息，也可以用上述方法加密。欢迎大家尝试！

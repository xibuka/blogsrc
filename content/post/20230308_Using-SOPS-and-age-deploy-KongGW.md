---
title: "20230308_Using SOPS and Age Deploy KongGW"
title: "Mozila SOPS+ageで実現するKong Gatewayセキュアデプロイメント"
date: 2023-03-08T16:41:18+09:00
draft: false
tags:
- Kong
- Security
---
## 背景

Kong Gatewayをデプロイする時に、データベースへの接続情報など平文で保存したくないデータが存在しています。これを解決するためにKong Secret Managerが開発され、AWS Secrets Managerなどの3rdパーティのサービスを利用すれば解決できます。しかし、環境によって外部のセキュリティサービスに接続できない時にこの機能は利用できません。ここで、Mozilaが開発したSOPSという暗号化ツールとGithub ActionのCI/CD workflowを利用し、普段暗号化されている設定ファイルをデプロイ時だけ復号し、Kong GWをインストールする実現することができました。

## 事前準備

CI/CD workflowを構築する前に、まずはローカル環境で暗号と復号を試してみましょう。以下の必要なツールをローカル環境にインストールします。

1. [age](https://github.com/FiloSottile/age/releases)
2. [sops](https://github.com/mozilla/sops/releases)

SOPSはとても便利な暗号化・復号化のツールで人気があります。PGP, age, Google cloud's KMS, Azure's key valut, Hashicorp Vaultなどをサポートしています。今回は他のクラウドサービスを極力利用しない方針のため、ageを選択しました。

ツールのインストールができましたら、`age-kengen --help`を試してみましょう。

```bash
$ age-keygen --help
Usage:
    age-keygen [-o OUTPUT]
    age-keygen -y [-o OUTPUT] [INPUT]

Options:
    -o, --output OUTPUT       Write the result to the file at path OUTPUT.
    -y                        Convert an identity file to a recipients file.
```

見た感じ大丈夫そうなので、早速Keyを生成しましょう。

## keyの生成

```
$ age-keygen -o sops-key.txt
Public key: age1hhpnj4ylj5z7qwaek0ncrq882ygmvnv4unup78u3djgmlezrmgkqshyatc

$ cat sops-key.txt
# created: 2023-03-08T06:07:28Z
# public key: age1hhpnj4ylj5z7qwaek0ncrq882ygmvnv4unup78u3djgmlezrmgkqshyatc
AGE-SECRET-KEY-1UHJNXS6RKYWA72RVED0ERGZVQ98N6MDFV6Y3CSPPN9JKLKSRH9GSQRLFAE
```

`sops-key.txt`ファイルに２種類のkeyが生成されました。Public keyは暗号化用、Private Keyは復号化用です。

## 設定ファイルの暗号化

SOPSをもっと便利に使うために、一つの設定ファイル `.sops.yaml`を作りましょう。これでコマンドラインからkeyを指定する必要がなくなります。ageの後ろに先ほど生成したPublic keyを記入しまして、encrypted_regexの部分は、どのセクションの内容を暗号化するかを設定するところです。

``` yaml
creation_rules:
  - encrypted_regex: '^(env|admin|proxy|enterprise|manager|portal|portalapi|postgresql)$'
    age: age1hhpnj4ylj5z7qwaek0ncrq882ygmvnv4unup78u3djgmlezrmgkqshyatc
```

上記の設定で、以下のコマンドで、Kong GWデプロイのファイルを暗号化することができます。

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

`image`のセクションは暗号化対象`encrypted_regex`にないので、平文のままになっております。

## 設定ファイルの復号化

複合するために、まずはPrivate Keyを`.config/sops/age/keys.txt`にコピーします。このパスはデフォルトのパスなので、 sopsコマンドを実行する時にはPrivate Keyを指定する必要がなくなります。
Private Keyの設定したら、以下のコマンドで上で暗号化したファイルを複合化することができます。

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

次に、実際にKong GatewayをデプロイCI/CDの中に上記の内容を追加すると、ユーザからは平文の設定ファイルを開示せずにデプロイできます。復号した設定ファイルもCI/CD workflow内にしか存在しないため、CI/CDが終了したら削除されます。

作業の流れは以下の感じです。

![workflow](https://raw.githubusercontent.com/robincher/kong-mozilla-sops-demo/master/assets/context.png)

1. Public/Privateの生成
1. 設定ファイルの暗号化
1. 設定ファイルをコミット
1. GitHub Action
    4-1. ツールのインストール
    4-2. Private keyの取得
    4-3. 設定ファイルの復号化
    4-4. helmで設定ファイルを使ってKong Gatewayをデプロイ

1から3は全てローカル環境で実施できます。気をつけたいのは、4-2 Private Key取得のところです。Github ActionのSecrets機能でPrivate Keyを事前に登録したら、CI/CD workflowで直接参照できますので、平文で表示される心配もなくなります。また、利用するPublic/Privateはペアじゃなかったら復号する時にエラーになりますのでご注意ください。

書いていたCI/CD workflowは、[main.yml](https://raw.githubusercontent.com/robincher/kong-mozilla-sops-demo/master/.github/workflows/main.yaml) から参照できます。暗号化した設定ファイルをコミットしたら、無事にKong Gatewayのインストールができますのでぜひみなさん試してみてください。

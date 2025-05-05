---
title: "decK CLIでKong API Gatewayを設定変更"
date: 2024-04-04T23:49:19+09:00
draft: false
tags:
- decK
- Kong Gateway
- APIOps
---

## Deck CLI

decKはAPIライフサイクル自動化（APIOps）のために開発されたコマンドラインツールである。これにより、開発者と運用チームは開発からデプロイまでAPIを管理し、API統合の一貫性、信頼性、スピードを確保できる。

decKコマンドは以下の機能と特徴を持っている。

- エクスポート(バックアップ)
  既存のKong構成をYAML形式の構成ファイルにエクスポートする

- インポート（リストア）
  エクスポートされた、または手書きの構成ファイルを使用して、Kong構成を反映する

- 差分と同期の機能
  decKは、構成ファイル内の構成とKongのDB内の構成を比較し、それを同期することができます。これは、構成の差分を検出することも可能
  
- 逆同期
  KongのDB内の構成があるのに、構成ファイルにない場合は、逆に構成ファイルへの同期もサポート

- 検証
  構成ファイルの文法エラー検証

- リセット
  Kongのデータベース内のすべてのエンティティを削除

- 並行操作
  KongのAdmin APIへの呼び出しが並行して実行され、複数のスレッドを使用して同期プロセスを高速化

- Kongとの認証
  `--headers Kong-Admin-Token:test`の形でHTTPヘッダーに認証情報を入れて、認証必要なKongへのアクセスが可能

- 複数の構成ファイルでKongの構成を管理
  エンティティ間で共有される一連のタグに基づいて、Kongの構成を複数のファイルに分割可能

- 構成管理の自動化
  decKはCIパイプラインの一部として設計されており、Kongに構成をプッシュするだけでなく、構成のドリフトも検出可能

以下は、サブコマンド単位で例を載せる

## 事前準備

以下のKong構成ファイルをベースにしています。ServiceとRouteがひとつずつ存在する状態

``` kong.yaml
_format_version: "3.0"
services:
- host: httpbin.org
  name: uuid-generator
  path: /
  protocol: http
  routes:
  - name: uuid-generator
    paths:
    - ~/uuid$
    strip_path: false
```

## deck gateway 関連

### deck gateway ping

まずはpingで疎通確認

```bash
deck gateway ping --headers Kong-Admin-Token:test
Successfully connected to Kong!
Kong version:  3.4.3.5
```

KongのAdmin APIの場所を指定しない場合、デフォルトは`localhost:8001`へ接続しにいく。
ローカルにないKongへの疎通確認をしたい場合は、`--kong-addr`でアドレスを指定する。

```bash
deck gateway ping --kong-addr http://18.178.66.113:8001 --headers Kong-Admin-Token:test
Successfully connected to Kong!
Kong version:  3.4.3.5
```

### deck gateway validate

構成ファイルの文法などをチェック。問題がない場合は何も出力しないが、構文エラーがある場合ちゃんと行数とエラーの内容を出力する。
このコマンドは、Kong Admin APIに接続して検証を行う。処理時間がかかりますが、重大なエラーなどを洗い出すことが可能。もしローカルのファイルのみを検証したい場合は、`deck file validate`を利用する。
検証の時にKongのDBへの変更などはありません。

```bash
deck gateway validate kong.yaml --headers Kong-Admin-Token:test
Error: 1 errors occurred:
  reading file kong.yaml: validating file content: unmarshaling file content: error converting YAML to JSON: yaml: line 7: could not find expected ':'
```

### deck gateway sync

上記の構成ファイルをKong Gatewayに反映する。デフォルトは標準入力から構成内容を読み込む。

```bash
$ cat kong.yaml | deck gateway sync --headers Kong-Admin-Token:test
creating service uuid-generator
creating route uuid-generator
Summary:
  Created: 2
  Updated: 0
  Deleted: 0
```

### deck gateway diff

ファイルを更新したあと、kong gateway diff を実行して、KongのDB内の構成とファイル上の構成の違いを確認

```bash
$ sed -i 's/protocol: http/protocol: https/g' kong.yaml
$ deck gateway diff kong.yaml --headers Kong-Admin-Token:test
updating service uuid-generator  {
   "connect_timeout": 60000,
   "enabled": true,
   "host": "httpbin.org",
   "id": "033e20b1-9a83-4f80-a75e-ee4f9b354676",
   "name": "uuid-generator",
   "path": "/",
   "port": 80,
-  "protocol": "http",
+  "protocol": "https",
   "read_timeout": 60000,
   "retries": 5,
   "write_timeout": 60000
 }

Summary:
  Created: 0
  Updated: 1
  Deleted: 0

```

ファイル上の構成を反映したい場合はもう一度deck gateway syncを実行する。

### deck gateway dump

逆にDB上の構成をファイルに反映したい場合、またはバックアップを取りたい場合は、dumpをする。
その後もう一度diffをすれば、DB上の構成がファイルに反映したことがわかる。

```bash
$ deck gateway dump -o kong.yaml --headers Kong-Admin-Token:test
File 'kong.yaml' already exists. Do you want to overwrite it? yes

$ deck gateway diff kong.yaml --headers Kong-Admin-Token:test
Summary:
  Created: 0
  Updated: 0
  Deleted: 0
```

### deck gateway reset

KongのDB上の構成を全て削除する。

```bash
deck gateway reset --headers Kong-Admin-Token:test
This will delete all configuration from Kong's database.
> Are you sure? yes
deleting route uuid-generator
deleting service uuid-generator
Summary:
  Created: 0
  Updated: 0
  Deleted: 2
```

## deck file 関連

deck fileは、主にKongの構成ファイルに関する処理を行う。

### deck file validate \

`deck gateway validate`と似ているが、Kong Admin APIへの通信がなくローカルファイルの文法チェックだけのため実行速度が速い。

```bash
deck file validate kong.yaml
Error: 1 errors occurred:
  reading file kong.yaml: validating file content: unmarshaling file content: error converting YAML to JSON: yaml: line 7: could not find expected ':'

```

### deck file kong2kic

Kongの構成ファイルをKubernetes用に変更する。
例えば、以下のKong.yamlの構成ファイルを例にする。

```kong.yaml
_format_version: "3.0"
services:
- connect_timeout: 60000
  enabled: true
  host: httpbin.org
  name: uuid-generator
  path: /
  port: 80
  protocol: http
  read_timeout: 60000
  retries: 5
  routes:
  - https_redirect_status_code: 426
    name: uuid-generator
    path_handling: v0
    paths:
    - ~/uuid$
    preserve_host: false
    protocols:
    - http
    - https
    regex_priority: 0
    request_buffering: true
    response_buffering: true
    strip_path: false
  write_timeout: 60000
```

#### HTTPRoute + Service (Default)

HTTPRoute + Serviceのリソースを生成させるために以下のコマンドを実行する。

```bash
deck file kong2kic -s kong.yaml
```

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  annotations:
    konghq.com/https-redirect-status-code: "426"
    konghq.com/path-handling: v0
    konghq.com/preserve-host: "false"
    konghq.com/regex-priority: "0"
    konghq.com/request-buffering: "true"
    konghq.com/response-buffering: "true"
    konghq.com/strip-path: "false"
  name: uuid-generator-uuid-generator
spec:
  parentRefs:
  - name: kong
---
apiVersion: v1
kind: Service
metadata:
  annotations:
    konghq.com/connect-timeout: "60000"
    konghq.com/path: /
    konghq.com/protocol: http
    konghq.com/read-timeout: "60000"
    konghq.com/retries: "5"
    konghq.com/write-timeout: "60000"
  name: uuid-generator
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: uuid-generator
---
```

#### Ingress + Service

Ingress + Serviceのリソースを生成させるために、--ingressオプションを追加してからコマンドを実行する。

```bash
deck file kong2kic -s kong.yaml --ingress
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    konghq.com/https-redirect-status-code: "426"
    konghq.com/path-handling: v0
    konghq.com/preserve-host: "false"
    konghq.com/protocols: http,https
    konghq.com/regex-priority: "0"
    konghq.com/request-buffering: "true"
    konghq.com/response-buffering: "true"
    konghq.com/strip-path: "false"
  name: uuid-generator-uuid-generator
spec:
  ingressClassName: kong
  rules:
  - http:
      paths:
      - backend:
          service:
            name: uuid-generator
            port:
              number: 80
        path: /~/uuid$
        pathType: ImplementationSpecific
---
apiVersion: v1
kind: Service
metadata:
  annotations:
    konghq.com/connect-timeout: "60000"
    konghq.com/path: /
    konghq.com/protocol: http
    konghq.com/read-timeout: "60000"
    konghq.com/retries: "5"
    konghq.com/write-timeout: "60000"
  name: uuid-generator
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: uuid-generator
---
```

### deck file openapi2kong

OpenAPI specifications（OAS）のソースからKong の構成ファイルに変換する
例えば以下のOASのファイルを例にする。ServiceとRouteだけではなく、Pluginも入っています。

```yaml
openapi: 3.0.0
tags:
  - description: Creates a random UUID and returns it in a JSON structure
    name: Generate UUID
  - description: Returns a delayed response (max of 10 seconds).
    name: Delayed Response
info:
  contact:
    email: wenhan.shi@konghq.com
    url: https://konghq.com/
  description: A simple service returning a UUID based on https://httpbin.org
  title: UUID generator based on httpbin.org
  version: 1.0.8
paths:
  /uuid:
    get:
      operationId: uuid
      summary: Return a UUID.
      description: Return a UUID
      responses:
        "200":
          description: A UUID4.
      tags:
        - Generate UUID
    x-kong-plugin-rate-limiting:
      enabled: true
      config:
        minute: 5
    x-kong-plugin-proxy-cache:
      enabled: true
      config:
        strategy: memory

servers:
  - url: https://httpbin.org/
```

以下のコマンドで一発変換するとこになります。ちゃんとプラグインの設定も変換されています。

```bash
deck file openapi2kong -s openapi.yaml
```

```yaml
_format_version: "3.0"
services:
- host: httpbin.org
  id: 50f943d2-3299-5315-adf6-7da92729c8ce
  name: uuid-generator-based-on-httpbin-org
  path: /
  plugins: []
  port: 443
  protocol: https
  routes:
  - id: c58bf17c-dfd9-544d-965b-cc3e26be87f1
    methods:
    - GET
    name: uuid-generator-based-on-httpbin-org_uuid
    paths:
    - ~/uuid$
    plugins:
    - config:
        strategy: memory
      enabled: true
      id: fc364f07-919d-5fd5-b9fe-ac6540848e4f
      name: proxy-cache
      tags: []
    - config:
        minute: 5
      enabled: true
      id: ff5cb72c-3698-5403-9420-3beb6c2fb26c
      name: rate-limiting
      tags: []
    regex_priority: 200
    strip_path: false
    tags: []
  tags: []
upstreams: []
```

### deck file add-plugins

Kongの構成ファイルにプラグインの定義を追加する。

いつもの以下の構成に対し

```yaml
_format_version: "3.0"
services:
- host: httpbin.org
  name: uuid-generator
  path: /
  port: 80
  protocol: http
  routes:
  - name: uuid-generator
    paths:
    - ~/uuid$
    strip_path: false
```

以下のコマンドを実行すると、`--selector='services[*]'`で書いたように、全てのServiceに`--config`で定義したプラグインを追加する。
`--selector`の表現を`='route[*]'`に変更すると、すべてのRouteにプラグインを追加する。

```bash
cat kong.yaml | deck file add-plugins --selector='services[*]' --config='{"plugins":[{"config":{"strategy":"memory"},"enabled":true,"name":"proxy-cache"}]}'
```

```yaml
_format_version: "3.0"
services:
- host: httpbin.org
  name: uuid-generator
  path: /
  plugins:
  - plugins:
    - config:
        strategy: memory
      enabled: true
      name: proxy-cache
  port: 80
  protocol: http
  routes:
  - name: uuid-generator
    paths:
    - ~/uuid$
    strip_path: false
```

上記の方法では、`--selector`と`--config`が全部コマンドラインに書いているのでコマンド自体が長くなる。
この二つのパラメータをファイルに保存して適用する方法もあります。例えば以下の内容をJSONファイルに保存する。

```proxy-cache.json
{ "_format_version": "1.0",
 "add-plugins": [
   { "selectors": [
      "service[*]"
     ],
     "overwrite": false,
     "plugins": [
       { "name": "proxy-cache",
         "config": {
           "strategy": "memory"
         }
       }
      ]
   }
 ]
}
```

そして、このファイルをadd-pluginsの後ろに追加したら、STDINからの構成内容にプラグインが追記される。

```bash
cat kong.yaml | deck file add-plugins proxy-cache.json
```

```yaml
_format_version: "3.0"
services:
- host: httpbin.org
  name: uuid-generator
  path: /
  plugins:
  - config:
      strategy: memory
    name: proxy-cache
  port: 80
  protocol: http
  routes:
  - name: uuid-generator
    paths:
    - ~/uuid$
    strip_path: false
```

まだまだサブコマンドがありますが、前半はここまでにしたいと思います。

- deck file add-tags - Add tags to objects in a decK file
- deck file convert - Convert files from one format into another format
- deck file lint - Validate a file against a ruleset
- deck file list-tags - List current tags from objects in a decK file
- deck file merge - Merge multiple decK files into one
- deck file namespace - Apply a namespace to routes in a decK file by prefixing the path.
- deck file patch - Apply patches on top of a decK file
- deck file remove-tags - Remove tags from objects in a decK file
- deck file render - Combines multiple complete configuration files and renders them as one Kong declarative config file.

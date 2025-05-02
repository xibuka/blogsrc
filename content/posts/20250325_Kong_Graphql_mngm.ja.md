---
title: "Kong GatewayでGraphQL APIへのアクセスと管理"
date: 2025-03-25T23:49:19+09:00
draft: false
tags:
- kong
- GraphQL
---

## GraphQL のおさらい

GraphQL は、Facebook が開発した API クエリ言語であり、従来の REST API よりも柔軟にデータを取得できる仕組みを提供します。

### GraphQL の特徴

- **単一のエンドポイント**: REST API では複数のエンドポイントが必要ですが、GraphQL では 1 つのエンドポイント (`/graphql`) に対して異なるクエリを送信できます。
- **必要なデータのみ取得**: クライアントが必要なフィールドだけを指定して取得できるため、不要なデータ転送を防げます。
- **型システム**: API のスキーマが型で定義されており、データ構造を明確に把握できます。

例えば、`https://countries.trevorblades.com/` という GraphQL API に対して、以下のようなクエリを送信すると、日本の国情報を取得できます。

```graphql
{
  country(code: "JP") {
    name
    capital
    currency
  }
}
```

このクエリを `curl` を使って実行する場合:

```sh
curl -X POST https://countries.trevorblades.com/ \
  -H "Content-Type: application/json" \
  -d '{"query": "{ country(code: \"JP\") { name capital currency } }"}'
```

レスポンス:

```json
{
  "data": {
    "country": {
      "name": "Japan",
      "capital": "Tokyo",
      "currency": "JPY"
    }
  }
}
```

GraphQL の強力な点は、クエリを変更することで取得するデータを柔軟に調整できることです。例えば、上記クエリから`capital`を除いて実行すると:

```sh
curl -X POST https://countries.trevorblades.com/ \
  -H "Content-Type: application/json" \
  -d '{"query": "{ country(code: \"JP\") { name currency } }"}'
```

レスポンスから`capital`の内容も無くなった:

```json
{
  "data": {
    "country": {
      "name": "Japan",
      "currency": "JPY"
    }
  }
}
```

このように、取得したいデータの種類を動的に変更できる点が特徴です。

### GraphQL のデメリット

- **複雑さ**: クライアントがクエリを設計する必要があり、シンプルな REST API に比べて学習コストが高い。
- **キャッシュが難しい**: REST API では URL ベースでキャッシュしやすいが、GraphQL は POST リクエストを基本とするため、キャッシュ戦略が複雑になる。
- **負荷の問題**: クライアントが複雑なクエリを送信すると、サーバー側の処理負担が増加する可能性がある。

## Kong の概要

Kong はオープンソースの API ゲートウェイであり、API の管理、認証、ルーティング、ロードバランシングなどを担います。

### Kong の役割

- **API 管理**: API の公開、認証、制限、監視が可能
- **プラグインによる拡張**: 認証、キャッシュ、レートリミット、変換などのプラグインを利用可能
- **負荷分散とスケーラビリティ**: 複数のバックエンドサービスに対するリクエストを適切に分配

Kongは、RESTful APIだけでなく、GraphQL APIのリクエストも管理できます。特に、GraphQLはその柔軟性と効率的なデータ取得が特徴ですが、これを実際に運用する際に便利なツールがKongです。

### Kongで利用できるGraphQL関連のプラグイン

- DeGraphQL: GraphQL APIをRESTful APIのように使えるように変換するプラグイン
- GraphQL Caching: GraphQLレスポンスをキャッシュし、同じリクエストに対する処理負荷を軽減するためのプラグイン
- GraphQL Rate Limiting: GraphQL APIに対するリクエスト数を制限するプラグイン

## DeGraphQL プラグインの紹介

**DeGraphQL** プラグインは、Kong において GraphQL を RESTful API のように扱えるようにするプラグインです。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/f028b415-adbe-46f8-bd0d-09f198da8de5.png)

### 主な機能

- GraphQL API へのリクエストを REST 形式で送信できるように変換
- クライアント側で GraphQL クエリを書く必要がなくなる
- 既存の REST API クライアントやツールで利用可能

これにより、GraphQL に詳しくない開発者でも、簡単にデータを取得できます。

---

### デモ: Kong を使って GraphQL へ RESTful のようにアクセス

#### Service と Route の作成

まず、GraphQL エンドポイントを指す Service を作成し、それに対応する Route を定義します。

```sh
# Service の作成
curl -i -X POST http://localhost:8001/services \
  --data "name=countries-graphql" \
  --data "url=https://countries.trevorblades.com/"

# Route の作成
curl -i -X POST http://localhost:8001/routes \
  --data "service.name=countries-graphql" \
  --data "paths[]=/dql"
```

#### DeGraphQL プラグインの有効化

次に、Service に DeGraphQL プラグインを作成します。このプラグインは **Service レイヤーでのみ作成可能** である点に注意してください。

```sh
curl -X POST http://localhost:8001/services/countries-graphql/plugins \
    --data name="degraphql"
```

#### DeGraphQL の Route 設定

最後に、GraphQL クエリの内容を設定するため、DeGraphQL の Routes を作成します。

```sh
curl -X POST http://localhost:8001/services/countries-graphql/degraphql/routes \
  --data uri='/:country' \
  --data query='query ($country:ID!) {
    country(code: $country) {
      name
      native
      capital
      emoji
      currency
      languages {
        code
        name
      }
    }
  }'
```

### Kong 経由で RESTful のようにアクセス

設定が完了したら、Kong を経由して REST API のようにアクセスできるか試してみます。

```sh
curl -X GET http://localhost:8000/dql/JP
```

このリクエストを実行すると、次のようなレスポンスが得られます。

```json
{
  "name": "Japan",
  "native": "日本",
  "capital": "Tokyo",
  "emoji": "🇯🇵",
  "currency": "JPY",
  "languages": [
    {
      "code": "ja",
      "name": "Japanese"
    }
  ]
}
}
```

このデモでは、Kong の DeGraphQL プラグインを使い、GraphQL API を REST API のように利用する方法を紹介しました。

### メリット

- GraphQL に不慣れな開発者でもシンプルな REST API のようにアクセス可能
- 既存の REST クライアントをそのまま利用可能
- API ゲートウェイとして Kong を活用し、柔軟なルーティングが可能

## GraphQL Proxy Caching Advanced の紹介

GraphQL Proxy Caching Advanced は、Kong における GraphQL API のキャッシュ機能を強化するプラグインです。GraphQL のレスポンスをキャッシュし、同じリクエストに対するレスポンスの再計算を防ぐことで、パフォーマンスを向上させます。

### 主な機能

- **リクエストのキャッシュ**: 同じクエリに対してキャッシュを適用し、バックエンドの負荷を軽減
- **キャッシュの有効期限設定**: TTL（Time-To-Live）を設定して、適切な期間キャッシュを保持
- **キャッシュのバイパス**: 必要に応じて特定のリクエストをキャッシュ対象外に設定可能

### GraphQL Proxy Caching Advanced のデモ

#### プラグインの有効化

まず、対象の Service に対して GraphQL Proxy Caching Advanced を有効にします。

```sh
curl -X POST http://localhost:8001/services/countries-graphql/plugins \
  --data name="graphql-proxy-cache-advanced" \
  --data config.strategy="memory" \
  --data config.cache_ttl=300
```

この設定では、キャッシュ戦略をメモリ（`memory`）とし、キャッシュの有効期限を 300 秒（5 分）に設定しています。キャッシュ戦略を`Redis`に保存することもできます。

#### キャッシュの動作確認

まずは1回目、キャッシュなしの状態でリクエストを送信します。

```sh
curl -vvv -X GET http://localhost:8000/dql/JP

...
< X-Cache-Key: a3dad8528d327acbab14c19dc9057727fc1bcf0a236d2c95110a174919507dbb
< X-Cache-Status: Miss
< X-Kong-Upstream-Latency: 174
< X-Kong-Proxy-Latency: 12
...
* Connection #0 to host localhost left intact
{"data":{"country":{"name":"Japan","native":"日本","capital":"Tokyo","emoji":"🇯🇵","currency":"JPY","languages":[{"code":"ja","name":"Japanese"}]}}}%                                                                                 
```

最初のリクエストではバックエンドの GraphQL API にリクエストが送られ、レスポンスが返されます。まだキャッシュがないため、`X-Cache-Status: Miss`となっていて、`< X-Kong-Upstream-Latency: 174`で示したようにレイテンシが174msかかりました。

続いて、同じリクエストを再度実行すると、

```sh
curl -vvv -X GET http://localhost:8000/dql/JP
...
< X-Cache-Key: a3dad8528d327acbab14c19dc9057727fc1bcf0a236d2c95110a174919507dbb
< X-Cache-Status: Hit
< X-Kong-Upstream-Latency: 0
< X-Kong-Proxy-Latency: 1
...
* Connection #0 to host localhost left intact
{"data":{"country":{"name":"Japan","native":"日本","capital":"Tokyo","emoji":"🇯🇵","currency":"JPY","languages":[{"code":"ja","name":"Japanese"}]}}}%                                                                                  
```

`X-Cache-Status: Hit`で示したように、キャッシュが有効になり、Kong から直接レスポンスが返されるようになります。また、`< X-Kong-Upstream-Latency: 0`となっているため、Upstream APIへのアクセスがないためレイテンシは0msです。

#### キャッシュの操作

このプラグインが提供したAPI Endpointを利用して、キャッシュの確認や削除を行うことができます。詳細については `https://docs.konghq.com/hub/kong-inc/graphql-proxy-cache-advanced/api/#managing-cache-entities` をご参考ください。

GraphQL Proxy Caching Advanced を利用することで、GraphQL API のパフォーマンスを向上させることができます。

- **リクエストのキャッシュにより、レスポンスの高速化とバックエンドの負荷軽減が可能**
- **適切なキャッシュ戦略と TTL を設定することで、データの鮮度とパフォーマンスのバランスを調整**
- **キャッシュのバイパスやクリア機能を活用して、柔軟なキャッシュ管理が可能**

## GraphQL Rate Limiting Advanced の紹介

GraphQL Rate Limiting Advanced は、Kong における GraphQL API に対してリクエスト数の制限を強化するプラグインです。このプラグインにより、過剰なリクエストを防止し、API サービスへの負荷を軽減することができます。

### 主な機能

- **リクエスト数制限**:  特定の時間帯におけるリクエスト数を制限し、サービスの過負荷を防止
- **個別ユーザーに対する制限**: ユーザーごとに制限を設定することで、個別の利用状況に対応
- **動的な制限設定**: リクエスト数の制限を柔軟に調整できる機能

### GraphQL Rate Limiting Advanced のデモ

#### プラグインの有効化

まず、対象の Service に対して GraphQL Rate Limiting Advanced を有効にします。

```bash
curl -i -X POST http://localhost:8001/services/countries-graphql/plugins \
  --data name=graphql-rate-limiting-advanced \
  --data config.limit=3,100 \
  --data config.window_size=60,3600 \
  --data config.sync_rate=1
```

この設定では、1 分間に最大 3 リクエスト、1 時間に最大 100 リクエストまで許可しています。

## まとめ

Kongを使うことで、GraphQL APIをより効率的に管理し、セキュリティやパフォーマンスを向上させることができます。DeGraphQLプラグインでRESTfulにGraphQLを扱えるようにしたり、Rate LimitingやCachingで負荷を管理したりすることで、運用の手間が減り、APIの可用性を高めることができます。

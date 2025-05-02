---
title: "Kong API Gateway入門 - Kong gateway入門 - 流量制限のやり方"
date: 2024-12-03T23:49:19+09:00
draft: false
tags:
- kong
- RateLimiting
---

## 流量制限（Rate Limiting）の重要性

現代のAPI経済において、流量制限（Rate Limiting）は、システムの安定性、セキュリティ、そしてコスト効率の観点から非常に重要な役割を果たしています。以下にその重要性を詳細に解説します。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/fa88a4e5-e1dc-e2b9-c1fc-a93b16ab9b6d.png)

### サーバーの負荷管理

APIは、予測不能な量のリクエストを受ける可能性があります。たとえば、突然の人気アプリケーションの登場や予期しないトラフィックの急増（いわゆる「スパイク」）によって、サーバーが過剰に負荷を受けることがあります。流量制限を設けることで、リクエストの最大許容量をコントロールし、サーバーが適切なパフォーマンスを維持できるようになります。

### 公平性の確保

流量制限は、すべてのユーザーが公平にAPIを利用できるようにするための重要な手段です。特定のユーザーやアプリケーションがリソースを独占することを防ぎ、他のユーザーの体験を守ります。

### セキュリティの向上

悪意のあるリクエストやDoS（Denial of Service）攻撃、ボットによる不正アクセスなどに対抗する手段として、流量制限は有効です。異常なリクエストパターンを検知して制限することで、APIとシステム全体を守ることができます。

### コスト管理

多くのクラウドプロバイダーやインフラサービスは、リクエスト数やデータ転送量に基づいて料金が発生します。無制限のリクエストを許可すると、予期しないコストが急増するリスクがあります。流量制限を設けることで、コストの予測がしやすくなり、無駄な支出を防ぎます。

## Kongにおける流量制限の基本的な仕組み

Kong Gatewayは、オープンソースで開発されたAPIゲートウェイで、APIの管理や保護を簡単に行うためのツールです。企業や開発者がAPIのセキュリティ、パフォーマンス、信頼性を向上させるために利用しています。Kong Gatewayでの流量制限（Rate Limiting）は、APIエンドポイントやごとのトラフィックを制御するための機能です。この機能は、プラグインとして提供されており、簡単に有効化して設定できます。

Kongの流量制限プラグインは、以下のように動作します：

1. リクエストのカウント
プラグインは、リクエストをカウントし、指定した時間枠（秒、分、時間、日など）内の許容範囲を超えると制限を適用します。
1. 閾値の超過時の動作
許容範囲を超えたリクエストは、HTTPステータスコード（通常は429 Too Many Requests）とともに拒否されます。カスタムメッセージを設定することも可能です。
1. ストレージの活用
カウント情報を保持するために、ローカルメモリやRedisなどの外部ストレージを使用します。これにより、分散環境での一貫性を確保します。
1. 柔軟な適用範囲
   - Service単位: 特定のAPIに制限を設定
   - Consumer単位: 個々のユーザーやアプリケーションごとに異なる制限を適用
   - Route単位: 特定のAPIエンドポイントのみに制限を設定

## 基本設定: Kongの流量制限プラグイン

Kongの流量制限プラグインは、以下の二つがあります。どれもリクエスト数を時間単位で制限します。たとえば、1分間に3リクエストまで許可するなど、簡単に設定可能です。

- [OSS] `https://docs.konghq.com/hub/kong-inc/rate-limiting/`
- [Enterprise] `https://docs.konghq.com/hub/kong-inc/rate-limiting-advanced/`

### Plugin設定

このブログでは、まずOSSの方から説明いたします。まず、テスト用のServiceとRouteを作成します。

```bash
curl -i -X POST http://localhost:8001/services/ \
  --data name=uuid_service \
  --data url=http://httpbin.org/uuid

curl -i -X POST http://localhost:8001/services/uuid_service/routes/ \
  --data name=uuid_route \
  --data paths=/uuid 
```

制限をかけていないため、無限にUUIDを生成することができます。

```bash
curl http://localhost:8000/uuid
{
  "uuid": "84677e6f-911c-457b-a74f-d825e84248cb"
}
```

次に、Serviceに対しRate Limitingのプラグインを作成します。

```bash
curl -X POST http://localhost:8001/services/uuid_service/plugins \
    --data "name=rate-limiting" \
    --data "config.minute=5"
```

このコマンドにより、以下の設定が `uuid_service`のService に登録されます：

- Plugin: Rate Limiting
- 制限: 1分間最大5回アクセス

もし有効範囲をRouteやConsumerにしたい場合は、`services/uuid_service`の部分を適切に書き換えてください。

### 動作確認

5回目のアクセスが大丈夫ですが、

```bash
curl http://localhost:8000/uuid
{
  "uuid": "6d1c137e-3707-4d50-a64c-89d7ac083ed0"
}
curl http://localhost:8000/uuid
{
  "uuid": "d3184480-124d-4ec4-a03a-c3f497260e2c"
}
curl http://localhost:8000/uuid
{
  "uuid": "3fb50124-535c-4851-b63c-4646054b88b4"
}
curl http://localhost:8000/uuid
{
  "uuid": "59db16f2-6aeb-4301-b88e-7fe28c3d0558"
}
curl http://localhost:8000/uuid
{
  "uuid": "56f4472b-5e68-4c9a-afcb-28a2899cc95b"
}
```

6回目からはエラーになります。

```bash
curl http://localhost:8000/uuid
{
  "message":"API rate limit exceeded",
  "request_id":"090e45286c55141b7fc47640d3df482d"
}
```

## 応用設定

### エラーメッセージとレスポンスコード

エラーメッセージやエラーコード情報をカスタマイズするには、以下を設定します：

```bash
curl -X POST http://localhost:8001/services/uuid_service/plugins \
    --data "name=rate-limiting" \
    --data "config.minute=5" \
    --data "config.error_code=429" \ \
    --data "config.error_message=ちょ待てよ"
```

5回以上にアクセスすると、カスタマイズされたレスポンスが帰ってきます。

```bash
curl -S http://localhost:8000/uuid
{
  "message":"ちょ待てよ",
  "request_id":"fd0f1d3851d1487748035047959b4242"
}%                                                                                                                                     
curl -I http://localhost:8000/uuid
HTTP/1.1 429 Too Many Requests
Date: Tue, 03 Dec 2024 08:21:25 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
X-RateLimit-Limit-Minute: 5
X-RateLimit-Remaining-Minute: 0
RateLimit-Reset: 35
Retry-After: 35
RateLimit-Remaining: 0
RateLimit-Limit: 5
Content-Length: 84
X-Kong-Response-Latency: 1
Server: kong/3.8.0.0-enterprise-edition
X-Kong-Request-Id: 2987f03c7d71364a57f6904500d3a915
```

### リクエスト数カウンターとRedisの活用

KongのRate Limitingプラグインは、リクエスト数をカウントするためのカウンターを、データベース、メモリ、またはRedisに保存する柔軟な仕組みを提供します。それぞれの保存方法には特性があり、環境に応じた選択が重要です。

#### データベースに保存

カウンターをデータベースに保存する場合、すべてのKongノードがデータベースに接続している必要があります。これにより、各ノード間で一貫したカウント情報を共有できます。しかし、dblessモード（データベースなしモード）やハイブリッドモードでは動作しないです。

#### メモリに保存

高速性が求められる単一ノード環境向けであり、分散環境では利用が制限されます。

#### Redisに保存

Redisを利用することで、クラスタ全体で共有可能なカウンターを実現します。すべてのKongノードが同じRedisインスタンスを参照するため、クラスタ全体で正確なカウントが可能です。また、Redisの性能を活用して、大規模なトラフィックにも対応できます。
ただし、Redisの利用にはセットアップの手間とRedis障害時の対策が必要です。

#### Redisを活用する設定例

以下のファイルを使って、docker composeでRedisの環境を構築します。`"--requirepass kong"`の部分はredisのpasswordを設定しています。

```yaml
version: "3.9"

services:
  redis:
    image: redis:latest
    container_name: redis-no-auth
    ports:
      - "6379:6379"
    command: ["redis-server", "--requirepass", "kong"]

```

以下のコマンドからRate Limitingの設定を行います。

```bash
curl -X POST http://localhost:8001/services/uuid_service/plugins \
    --data "name=rate-limiting" \
    --data "config.minute=5" \
    --data "config.policy=redis" \
    --data "config.redis.host=18.178.66.113" \
    --data "config.redis.port=6379" \
    --data "config.redis.username=default" \
    --data "config.redis.password=kong" 
```

- `config.policy=redis` : カウンターをRedisに保存
- `config.host` : Redisのホストネーム
- `config.port` : Redisのport
- `config.username` : RedisにアクセスするためのUsername、Redis側のデフォルトは`default`
- `config.password` : Redisにアクセスするためのpassword、今回は`kong`を利用

何回かリクエストを送ったら、以下のコマンドでRedis内のカウンターを確認することが可能です。

```bash
# Redis Containerに入り
> docker exec -it 51 sh

# passwordを使ってログイン
> redis-cli -a kong

# ここで一回リクエストを送信し、keyをリストアップ
127.0.0.1:6379> keys *
1) "ratelimit:00000000-0000-0000-0000-000000000000:628a172c-a98f-4355-a09b-f78f8e7f2562:172.21.0.1:1733231580000:minute"

# このkeyのvalueを確認し、1であることを確認
127.0.0.1:6379> get ratelimit:00000000-0000-0000-0000-000000000000:628a172c-a98f-4355-a09b-f78f8e7f2562:172.21.0.1:1733231580000:minute
"1"
```

### 時間による制限を変更

Pre-function と Rate Limitingの組み合わせで、時間により流量制限の回数を変更することができます。実際には一つのServiceに二つのRouteを作成し、それぞれのRouteに異なるHeaderを条件にしています。Pre-functionで時間により異なるHeaderを入れることによって、本機能を実現しています。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/bc2c03f6-2bd3-24bd-9cc9-5d56c3967ef4.png)

まずはテスト用のServiceを作成します。

```bash
curl -i -X POST http://localhost:8001/services \
  --data "name=httpbin" \
  --data "url=https://httpbin.konghq.com/anything"
```

次に、二つのRouteを作成します。パスが同じですが、Headersの条件が異なります。

```bash
curl -i -X POST http://localhost:8001/services/httpbin/routes \
   --data "name=peak" \
   --data "paths=/httpbin" \
   --data "headers.X-Peak=true"

curl -i -X POST http://localhost:8001/services/httpbin/routes \
   --data "name=off-peak" \
   --data "paths=/httpbin" \
   --data "headers.X-Off-Peak=true"
```

次に、この二つのRouteに対し、それぞれRate Limitingのプラグインを設定します。

```bash
curl -i -X POST http://localhost:8001/routes/peak/plugins/  \
   --data "name=rate-limiting" \
   --data "config.minute=10" 

curl -i -X POST http://localhost:8001/routes/off-peak/plugins/  \
   --data "name=rate-limiting" \
   --data "config.minute=60" 
```

最後に、Pre-functionでPeakとoff-peakのRouteにトラフィックが入るようにHeadersを設定します。

以下の内容を`ratelimit.lua`に保存します。この関数は、OSの時刻に基づいて時刻を決定し、決定された時刻(08:00 - 17:00)に基づいて`Header`を設定する。

```ratelimit.lua
local hour = os.date("*t").hour 
if hour >= 8 and hour <= 17 
then
    kong.service.request.set_header("X-Peak","true") 
else
    kong.service.request.set_header("X-Off-Peak","true") 
end
```

rewrite phaseで上記のコードが実行されるように設定します。

```bash
curl -i -X POST http://localhost:8001/plugins \
    --form "name=pre-function" \
    --form "config.rewrite[1]=@ratelimit.lua"
```

これで、業務時間内(08:00 - 17:00)の間は10回/分、業務時間外の間は60回/分を実現することが可能になります。

## OSSとEnterpriseの違い

Rate Limiting AdvancedのDoc[ページ](https://docs.konghq.com/hub/kong-inc/rate-limiting-advanced/ )では、OSSのプラグインとの違いが書かれています。

- Multiple Limits and Window Sizes
  - 例えば1日1000回と制限をかけていたが、最後の1分間で1000回を集中的に送信するとAPI側の負担になります。ここで1日1000回＋1分60回のように複数の制限を同じプラグインにかけることが可能になり、この問題が解決になります
- Redis Sentinel, Redis clusterとRedis SSLをサポート
- より良いスループット性能と准确性
- より多い流量制限のアルゴリズム
- Consumer groups サポート

などが挙げられます。

## おわりに

この記事では、Kong Gatewayにおける流量制限の重要性と、その基本的な仕組みや設定方法について解説しました。流量制限は、APIを安定して運用し、セキュリティやコストを管理するための鍵となる技術です。Kongの柔軟なプラグイン設計により、簡単かつ効率的にこの機能を活用できます。

KongのOSS版でも十分な機能が備わっていますが、より複雑な要件に対応する場合は、Enterprise版の利用も検討してください。企業のニーズに合わせた追加機能や性能向上が期待できます。

この記事が、Kongを活用したAPI管理の参考になれば幸いです。今後も技術ブログを通じて、APIやマイクロサービスの運用に役立つ情報をお届けします。興味がある方は、ぜひ次回の記事もチェックしてください！

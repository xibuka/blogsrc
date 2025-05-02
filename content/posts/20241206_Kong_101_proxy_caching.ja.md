---
title: "Kong gateway入門 - キャッシュ活用で性能向上"
date: 2024-12-06T23:49:19+09:00
draft: false
tags:
- kong
- Caching
---

## はじめに

APIゲートウェイにおけるキャッシュの主な目的は以下の通りです：

- 高速なレスポンス
- バックエンドの負荷軽減
- コスト削減

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/6ed481cd-b8b3-c503-71cb-4cc8d67bef65.png)

上段（リクエスト1回目）の流れ

1. クライアントがKong Gatewayにリクエストを送信
1. Kong Gatewayはこのリクエストをバックエンド（上流のサービス）に転送
1. バックエンドからのレスポンスをKong Gatewayが受け取り、このレスポンスをキャッシュ（Response Cache）として保存
1. レスポンスをConsumer側に返す

下段（リクエスト2回目）の流れ

1. クライアントが同じリクエストを送信
1. Kong Gatewayはキャッシュを確認し、保存されているレスポンスを直接回答
1. この場合、バックエンドにアクセスする必要がなくなるため、応答速度が大幅に向上
1. TTL（キャッシュの有効期限）が切れていない限り、このキャッシュが利用可能

Kongのキャッシュ機能は、プラグインで実現しています。プラグインを有効化し、必要な設定を加えるだけでキャッシュ機能を利用可能ですので簡単なセットアップができます。また、キャッシュの有効期間や対象データを細かく制御でき、ユースケースに応じた設定が可能です。さらに、キャッシュ自体を外に保存することができ、大規模なシステムでも効果的に動作し、Kongの高いスケーラビリティと連携します。

## キャッシュの基本概念

キャッシュは、頻繁にアクセスされるデータを一時的に保存し、高速に提供する仕組みです。多くのキャッシュデータをRAM上に保存し、極めて高速なレスポンスを実現することができます。キャッシュには以下の3つの構成要素があります：

1. キャッシュキー: 保存されたデータを特定するための識別子
2. キャッシュデータ: 保存される実際のレスポンスデータ
3. TTL（Time-To-Live）: データの有効期限

## Kong Gatewayで提供されるキャッシュ機能

Kongではキャッシュ機能を提供するプラグインは以下の二つがあります。

[Proxy Caching](https://docs.konghq.com/hub/kong-inc/proxy-cache/)
[Proxy Caching Advanced](https://docs.konghq.com/hub/kong-inc/proxy-cache-advanced/)

### Proxy Caching

Proxy Cachingプラグインは、HTTPレスポンスをキャッシュし、次回の同様のリクエストに対してキャッシュデータを直接返す仕組みです。これにより、バックエンドサービスへのアクセスを最小限に抑え、APIのパフォーマンスを向上させます。

まず、テスト用のServiceとRouteを作成します。

```bash
curl -i -X POST http://localhost:8001/services/ \
  --data name=uuid_service \
  --data url=http://httpbin.org/uuid

curl -i -X POST http://localhost:8001/services/uuid_service/routes/ \
  --data name=uuid_route \
  --data paths=/uuid 
```

次に、Serviceに対しProxy Cachingのプラグインを作成します。

#### Pluginの設定

```bash
curl -X POST http://localhost:8001/services/uuid_service/plugins \
  --data "name=proxy-cache" \
  --data "config.strategy=memory" 
```

このコマンドにより、以下の設定が uuid_serviceのService に登録されます：

Plugin: Proxy Cache
キャッシュの保存先: Memory

#### 動作確認

まず一回目のリクエストを送信します。

```bash
curl -v http://localhost:8000/uuid
*   Trying 127.0.0.1:8000...
* Connected to localhost (127.0.0.1) port 8000 (#0)
> GET /uuid HTTP/1.1
> Host: localhost:8000
> User-Agent: curl/7.81.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Content-Type: application/json
< Content-Length: 53
< Connection: keep-alive
< X-Cache-Key: 3ad4f7eda13f4b2a40191b6882d45de0f2bf8d4ba4b454604f7c08e4ae1eb094
< X-Cache-Status: Miss
< Date: Thu, 05 Dec 2024 15:27:09 GMT
< Server: gunicorn/19.9.0
< Access-Control-Allow-Origin: *
< Access-Control-Allow-Credentials: true
< X-Kong-Upstream-Latency: 480
< X-Kong-Proxy-Latency: 9
< Via: 1.1 kong/3.8.0.0-enterprise-edition
< X-Kong-Request-Id: 558aac59e7283e6c9898897e65009b7f
< 
{
  "uuid": "d93f8bf3-e610-48bf-81a7-ae656e7d868c"
}
* Connection #0 to host localhost left intact
```

responseを確認しましょう

- X-Cache-Key: リクエスト単位で計算されたCacheのkeyです。詳細の計算方法などは[ここ](https://docs.konghq.com/hub/kong-inc/proxy-cache/#cache-key)を参考
- X-Cache-Status: 利用可能なキャッシュの状態です。一回目のためキャッシュにレスポンスがまだありません、そのため`Miss`
- X-Kong-Upstream-Latency: KongからUpstream APIへのレイテンシ。アクセスが必要のため、480msかかりました

次に、同じ端末から同じリクエストをもう一度送信します。

```bash
curl -v http://localhost:8000/uuid
*   Trying 127.0.0.1:8000...
* Connected to localhost (127.0.0.1) port 8000 (#0)
> GET /uuid HTTP/1.1
> Host: localhost:8000
> User-Agent: curl/7.81.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Content-Type: application/json
< Connection: keep-alive
< X-Cache-Key: 3ad4f7eda13f4b2a40191b6882d45de0f2bf8d4ba4b454604f7c08e4ae1eb094
< Server: gunicorn/19.9.0
< Access-Control-Allow-Credentials: true
< X-Cache-Status: Hit
< age: 3
< Access-Control-Allow-Origin: *
< Date: Thu, 05 Dec 2024 15:33:31 GMT
< Content-Length: 53
< X-Kong-Upstream-Latency: 0
< X-Kong-Proxy-Latency: 1
< Via: 1.1 kong/3.8.0.0-enterprise-edition
< X-Kong-Request-Id: 3e8cfb3cb412c516262f94299adccb4d
< 
{
  "uuid": "d93f8bf3-e610-48bf-81a7-ae656e7d868c"
}
* Connection #0 to host localhost left intact
```

一回目のレスポンスと比較すると

- X-Cache-Key: 同じリクエストのためkeyが同じ
- X-Cache-Status: ２回目のためキャッシュにレスポンスが保存されています。利用可能のため`Hit`
- X-Kong-Upstream-Latency: KongからUpstream APIへアクセスが不要のため、0msになりました。

結果として、もともと480msかかったレイテンシが、0msまで削減され、レスポンス時間が短縮になりました。

#### Memoryにキャッシュを保存した時の問題

Kong Gatewayのキャッシュを**Memory（メモリ）**に保存する場合、ノード数が１つのみなら問題ないですが、複数ノードが存在する環境では以下のような懸念があります。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/d8175cd4-b550-ff75-4e1c-96b94d2e6c46.png)

- 各ノードは独自のメモリを持っており、キャッシュデータはそれぞれのノードのローカルに保存されます
- クライアントが複数ノード間でロードバランシングされる場合、ノード間でキャッシュが共有されないため、リクエストによってはキャッシュが存在しない（キャッシュミス）状況が発生します
- ノードが再起動されると、メモリキャッシュ内のデータは完全に消失し、バックエンドサーバーへの負荷は急増する可能性があります

この問題を解決するために、キャッシュをノード間に共有する必要があります。OSSのProxy CachingにはMemory以外の選択肢がないので、Proxy Caching AdvancedではMemoryの他にRedisを選択することができます。

### Proxy Caching Advanced

Kong GatewayのProxy Caching Advancedプラグインでは、キャッシュをRedisに保存することで、複数ノード間でキャッシュを共有し、一貫性のあるパフォーマンス向上が可能です。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/39f5e640-2422-e406-d720-4740bf0f8452.png)

#### Pluginの設定

Redisを利用する際に設定すべき主要な項目は以下の通りです：

| 設定項目 | 説明 | 例 |
|:-|:-|:-|
| strategy | キャッシュ保存手法 | redis |
| redis.host | Redisサーバーのホスト名またはIPアドレス | 127.0.0.1 |
| redis.port | Redisサーバーのポート番号  | 6379  |
| redis.password |Redisサーバーへの接続時に必要なパスワード |kong    |

```bash
curl -X POST http://localhost:8001/services/uuid_service/plugins \
  --data "name=proxy-cache-advanced" \
  --data "config.strategy=redis" \
  --data "config.redis.host=18.178.66.113" \
  --data "config.redis.port=6379" \
  --data "config.redis.password=kong" 
```

#### 動作確認

上記を設定した後、　上記の確認方法と同じく、同じリクエストを2回投げたら、2回目のアクセス時間が短縮になります。

```bash
curl -v http://localhost:8000/uuid
*   Trying 127.0.0.1:8000...
* Connected to localhost (127.0.0.1) port 8000 (#0)
> GET /uuid HTTP/1.1
> Host: localhost:8000
> User-Agent: curl/7.81.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Content-Type: application/json
< Content-Length: 53
< Connection: keep-alive
< X-Cache-Key: 3ad4f7eda13f4b2a40191b6882d45de0f2bf8d4ba4b454604f7c08e4ae1eb094
< X-Cache-Status: Miss
< Date: Thu, 05 Dec 2024 16:45:34 GMT
< Server: gunicorn/19.9.0
< Access-Control-Allow-Origin: *
< Access-Control-Allow-Credentials: true
< X-Kong-Upstream-Latency: 332
< X-Kong-Proxy-Latency: 8
< Via: 1.1 kong/3.8.0.0-enterprise-edition
< X-Kong-Request-Id: 7d25706ce575d268770b4a4983d5c71a
< 
{
  "uuid": "58c02bf6-4437-4720-aa8d-a41d30677ba6"
}
* Connection #0 to host localhost left intact
curl -v http://localhost:8000/uuid
*   Trying 127.0.0.1:8000...
* Connected to localhost (127.0.0.1) port 8000 (#0)
> GET /uuid HTTP/1.1
> Host: localhost:8000
> User-Agent: curl/7.81.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Content-Type: application/json
< Connection: keep-alive
< X-Cache-Key: 3ad4f7eda13f4b2a40191b6882d45de0f2bf8d4ba4b454604f7c08e4ae1eb094
< Server: gunicorn/19.9.0
< Access-Control-Allow-Credentials: true
< X-Cache-Status: Hit
< age: 2
< Access-Control-Allow-Origin: *
< Date: Thu, 05 Dec 2024 16:45:34 GMT
< Content-Length: 53
< X-Kong-Upstream-Latency: 0
< X-Kong-Proxy-Latency: 2
< Via: 1.1 kong/3.8.0.0-enterprise-edition
< X-Kong-Request-Id: e67e4f76b5621e2e3f8f7e6d36d59b79
< 
{
  "uuid": "58c02bf6-4437-4720-aa8d-a41d30677ba6"
}
* Connection #0 to host localhost left intact
```

## まとめ

この記事では、Kong Gatewayでキャッシュの説明と活用方法を説明しました。キャッシュがヒットした時に、レスポンスタイムが削減することを確認しました。
シングルノードの場合に、メモリにキャッシュを保存するのは大丈夫ですが、複数ノードの場合に、Proxy Caching Advancedを使ってRedisに保存しましょう。

---
title: "Kong API Gateway入門 - ServiceとRouteを理解する：基本から応用まで"
date: 2024-12-01T23:49:19+09:00
draft: false
tags:
- kong
---

Kong Gatewayを活用する際に重要な役割を果たすのが「サービス (Service)」と「ルート (Route)」です。サービスがAPIリクエストの転送先を定義する一方で、ルートはそのサービスにリクエストをマッピングするルールを定めます。

## サービスとは

サービスは、Kong Gatewayがプロキシする外部APIやマイクロサービスの情報を定義したものです。具体的には、リクエストを転送する先のURL、ホスト名、ポート番号、プロトコルなどを設定します。

例えば、Kongを使ってバックエンドの「ユーザーAPI」をプロキシしたい場合、そのAPIをサービスとして登録します。このとき、Kongはクライアントからのリクエストを受け取り、そのリクエストを登録されたサービスに転送します。Kongにサービスを作成する際に設定する主な項目は以下の通りです：

- name: サービスの名前。識別のためのラベルとして機能します
- host: リクエストを転送する先のホスト名（例: example.com）
- port: 接続先のポート番号（デフォルト: 80または443）
- protocol: 使用するプロトコル（httpまたはhttps）
- path: 転送先の特定のパス（例: /api/v1/users）

## ルートとは

サービスは単独では機能せず、「ルート (Route)」と連携して使用されます。ルートは、クライアントからのリクエストを特定のサービスにマッピングするための設定です。ルートでは以下のような条件を指定できます：

- パス (Path): クライアントがアクセスするURLのパス
- メソッド (Method): HTTPメソッド（例: GET, POST）
- ホスト名 (Host): リクエストのホストヘッダー
- ヘッダー (Header): 特定のHTTPヘッダー値

ルートの設定により、Kongはどのリクエストをどのサービスに転送するかを判断します。

## 実用例

### 1つのServiceと1つのRouteを構築

この例では、以下のように1つのServiceを一つのRouteで公開する方法を説明します。`http://httpbin.org/uuid` という外部APIをプロキシするサービスをKong Gatewayに登録し、それを`/uuid`というパスで公開します。公開されたエンドポイントにアクセスすると、UUID（ユニークな識別子）が取得できます。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/1b4773ab-6970-2468-3c58-da6c1d30256d.png)

まず、以下のコマンドを使用して、`http://httpbin.org/uuid`をターゲットとするサービスを作成します：

```bash
curl -i -X POST http://localhost:8001/services/ \
  --data name=uuid_service \
  --data url=http://httpbin.org/uuid
```

このコマンドにより、以下の設定がKongに登録されます：

- サービス名: uuid_service
- 転送先URL: `http://httpbin.org/uuid`

次に、このサービスを公開するためのルートを作成します。以下のコマンドを使用して、/uuidというパスでこのサービスを公開します：

```bash
curl -i -X POST http://localhost:8001/services/uuid_service/routes/ \
  --data name=uuid_route \
  --data paths=/uuid 
```

このコマンドで登録されたルートには、以下の設定が含まれます：

- ルート名: uuid_route
- 公開パス: /uuid

これにより、クライアントがKong Gatewayのエンドポイント（例: `http://localhost:8000/uuid`）にリクエストを送ると、Kongはリクエストを`http://httpbin.org/uuid`に転送します。

すべての設定が完了したら、実際にリクエストを送信して接続を確認します。以下のコマンドを使用して、Kong Gateway経由でAPIにアクセスします：

```bash
curl http://localhost:8000/uuid
{
  "uuid": "84677e6f-911c-457b-a74f-d825e84248cb"
}
```

この結果から、Kong Gatewayが正しくリクエストをプロキシしていることが確認できます。

### 1つのServiceと2つのRouteを構築

一つのサービス (user-service) に対して、異なるパスを持つ2つのルートを設定することもできます。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/987145e5-95e4-fdd2-63ed-0190e6b9f2cf.png)

複数ルートの利点として:

- API構造の柔軟性: 一つのサービスに異なるパスを割り当てることで、クライアントごとにAPIのアクセス方法をカスタマイズできます
- 管理の簡素化: 複数のルートがある場合、ルート単位でプラグイン（認証やキャッシングなど）を適用できます
- 効率的なトラフィック制御: 異なるパスごとにルーティングルールを設定することで、負荷分散やセキュリティ管理が容易になります

uuid_serviceとuuid_routeの作成は上記の同じなので割愛します。

uuid_route_newの作成は、基本同じコマンドでできます。

```bash
curl -i -X POST http://localhost:8001/services/uuid_service/routes/ \
  --data name=uuid_route_new \
  --data paths=/uuid_new
```

すべての設定が完了したら、二つのRouteにリクエストを送信して確認してみてください。両方とも正しくリクエストをプロキシしていることが確認できます。

```bash
curl http://localhost:8000/uuid
{
  "uuid": "b25f73f6-0a77-4a06-a611-97082b0ea449"
}
curl http://localhost:8000/uuid_new
{
  "uuid": "5ba6503d-ba06-41d7-9e30-880074513d3a"
}
```

### 1つのServiceと2つのRouteを構築し、RouteのPathをServiceに継承

本セクションでは、1つのサービスに2つのルートを設定し、ルートがサービスのパス設定を継承する方法を詳しく解説します。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/acb7d09b-8d74-073d-be97-2572e0328888.png)

今回のシナリオでは、以下の設定を行います：

- サービス: `http://httpbin.org` をターゲットとするサービスを登録
- ルート1: /uuid を公開パスとし、サービスの /uuid パスを継承
- ルート2: /ip を公開パスとし、サービスの /ip パスを継承

この設定により、次のようなリクエストが可能になります：

- `http://localhost:8000/uuid` → `http://httpbin.org/uuid`
- `http://localhost:8000/ip` → `http://httpbin.org/ip`

#### サービスを登録する

まず、ターゲットとなる外部APIをプロキシするサービスを登録します。作り方は上記と同じですが、今回のURLにPathは`/`を登録していきます。

```bash
curl -i -X POST http://localhost:8001/services/ \
  --data name=httpbin_service \
  --data url=http://httpbin.org
```

#### ルートuuidを作成する

1つ目のルートを作成し、`/uuid`パスで公開します。`strip_path=false` を設定することで、この`/uuid`パスはサービスの最後に追加されます。
`strip_path` は、Kong Gatewayでルートを設定する際の重要なオプションで、リクエストのURLパスをそのままサービスに転送するかどうかを制御します。このパラメータのデフォルト設定はstrip_path=trueであり、ルートに指定されたパスが、リクエストをサービスに転送するの時に削除されます。
`strip_path=false`を設定することで、ルートに指定されたパスがそのままサービスに転送されます。

以下のコマンドを使用します：

```bash
curl -i -X POST http://localhost:8001/services/httpbin_service/routes/ \
  --data name=uuid_route \
  --data paths=/uuid \
  --data strip_path=false
```

#### ルートipを作成する

以下のコマンドで2つ目のルートを作成し、/ipパスで公開します。

```bash
curl -i -X POST http://localhost:8001/services/httpbin_service/routes/ \
  --data name=ip_route \
  --data paths=/ip \
  --data strip_path=false
```

#### 設定を確認

すべての設定が完了したら、エンドポイントにリクエストを送信して動作を確認します。

##### /uuidエンドポイントの確認

```bash
curl http://localhost:8000/uuid
{
  "uuid": "91c0b30e-220d-4766-b41b-fc428d25f9d0"
}
```

##### /ipエンドポイントの確認

```bash
curl http://localhost:8000/ip
{
  "origin": "172.21.0.1, x.x.x.x"
}
```

`strip_path=false`を利用することで、サービス側のパス構造を保持しながら柔軟なルーティングを実現できます。

この手法は以下の場面で有効です：

- 外部APIが複数のエンドポイントを提供しており、それぞれを異なるパスで公開したい場合
- クライアントに公開するパス構造をシンプルに保ちながら、サービスの既存パスを活用したい場合

## まとめ

Kong Gatewayの「サービス」と「ルート」を適切に設定することで、柔軟なAPIルーティングが実現できます。サービスは外部APIやマイクロサービスの情報を定義し、ルートはクライアントのリクエストをそのサービスにマッピングします。さらに、strip_path=falseを活用することで、公開パスをサービスのパス構造に継承させることが可能です。

これからは、認証、流量制限、キャッシングなどのプラグインを活用し、Kong Gatewayの機能をさらに強化する方法を解説しますのでお楽しみに！

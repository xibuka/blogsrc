---
title: "Konnect + AWS ECSでAPI Gateway環境を構築する"
date: 2025-05-01T23:49:19+09:00
draft: false
tags:
- kong
- Konnect
- ECS
---

[Kong Konnect](https://konghq.com/kong-konnect/) のData Planeとして、AWS ECS（Elastic Container Service）Fargate を使ってマイクロサービスをデプロイし、API Gateway環境の構築方法を紹介します。

## 準備するもの
- AWSアカウント
- Kong Konnectアカウント

## 構築手順

### Kong Konnect側

[Konnect](https://cloud.konghq.com/us/overview/)にログインし、`Gateway manager` -> `Data Plane Nodes` -> `Configure data plane`の順でData Plane作成画面にきて、`Generate Certificate`をクリックしてdocker runのコマンドが生成されます。このコマンドのパラメータが以降使いますのでコピーしていきます。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/c869a45c-04df-4f70-ac9e-8c23757429d0.png)

証明書が生成されたらKonnect側の作業が終わります。この証明書とkeyに改行が入っています、後でECSの環境変数として設定するため、下のコマンドで一行になるように変更します。

```bash
awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' tls.key
```

### AWS ECS側

#### コンテナーの定義

`AWS ECS` -> `Task definitions` -> `Create new task definition with JSON` でコンテナーの定義を行います。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/6dd7ead4-3cf4-47b1-8e31-f8a15ca0891a.png)

利用するJSONは以下になります。

```json
{
  "family": "kong-data-plane",
  "networkMode": "awsvpc",
  "containerDefinitions": [
    {
      "name": "kong-data-plane",
      "image": "kong/kong-gateway:3.10",
      "essential": true,
      "environment": [
        {
          "name": "KONG_ROLE",
          "value": "data_plane"
        },
        {
          "name": "KONG_DATABASE",
          "value": "off"
        },
        {
          "name": "KONG_VITALS",
          "value": "off"
        },
        {
          "name": "KONG_CLUSTER_MTLS",
          "value": "pki"
        },
        {
          "name": "KONG_CLUSTER_CONTROL_PLANE",
          "value": "xxxxxxxxxxxx.us.cp0.konghq.com:443"
        },
        {
          "name": "KONG_CLUSTER_SERVER_NAME",
          "value": "xxxxxxxxxxxx.us.cp0.konghq.com"
        },
        {
          "name": "KONG_CLUSTER_TELEMETRY_ENDPOINT",
          "value": "xxxxxxxxxxxx.us.tp0.konghq.com:443"
        },
        {
          "name": "KONG_CLUSTER_TELEMETRY_SERVER_NAME",
          "value": "xxxxxxxxxxxx.us.tp0.konghq.com"
        },
        {
          "name": "KONG_CLUSTER_CERT",
          "value": "<CERT in one line>"
        },
        {
          "name": "KONG_CLUSTER_CERT_KEY",
          "value": "<CERT key in one line>"
        },
        {
          "name": "KONG_LUA_SSL_TRUSTED_CERTIFICATE",
          "value": "system"
        },
        {
          "name": "KONG_KONNECT_MODE",
          "value": "on"
        },
        {
          "name": "KONG_CLUSTER_DP_LABELS",
          "value": "created-by:quickstart,type:docker-linuxdockerOS"
        },
        {
          "name": "KONG_ROUTER_FLAVOR",
          "value": "expressions"
        },
      ],
      "portMappings": [
        {
          "containerPort": 8000,
          "hostPort": 8000,
          "protocol": "tcp",
          "appProtocol": "http"
        },
        {
          "containerPort": 8443,
          "hostPort": 8443,
          "protocol": "tcp",
          "appProtocol": "http"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/kong-data-plane",
          "awslogs-region": "ap-northeast-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ],
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::xxxxxxxxxxxx:role/ecsTaskExecutionRole"
}
```

`docker run`コマンドを参考し、以下のKong関連のパラメータを修正する必要があります。

- `KONG_CLUSTER_CONTROL_PLANE`
- `KONG_CLUSTER_SERVER_NAME`
- `KONG_CLUSTER_TELEMETRY_ENDPOINT`
- `KONG_CLUSTER_TELEMETRY_SERVER_NAME`
- `KONG_CLUSTER_CERT`
- `KONG_CLUSTER_CERT_KEY`

AWS側の設定に合わせて修正すべきパラメータは

- `logConfiguration.options`
- `executionRoleArn`

#### Serviceを起動

Clusterを作成した後に、ServiceをCreateします。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/f2c3ba5a-c860-43f7-9919-785c4b311f1a.png)

Serviceの作成にいくつかポイントがあります。その他は適切に設定してください。

- `Service Details`内の`Task definition family`は先ほど作ったTaskを選択
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/0416d0d0-aa08-47af-9cc7-3ffa41112d68.png)

- `Networking`内で選択する`Security group`では、`8000`と`8443`ポートを公開する必要がある
- 外部からアクセスする必要があるため、`Public IP`をTurned onにする
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/7156874a-2ef7-416a-9f81-7152ad5fc486.png)

設定が完了したら、ページ右下のCreateをクリックします。

## 動作確認

Serviceが無事起動したら、Konnectの`Data Plane Nodes`でECS Data Planeを確認することができます。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/fc43b78c-8f29-4b84-b992-6c45272bc3a2.png)

AWS ECS側では、Service以下のTaskで、付与された`Public IP`のアドレスを確認できます。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/c1450735-db1d-464c-84c0-b3d900e13e43.png)

アドレスにアクセスしてみると、`no Route matched with those values`が返され、Kong Data Planeの構築が無事完了したことを確認できます。

```bash
$ http 43.207.xx.xx:8000
HTTP/1.1 404 Not Found
Connection: keep-alive
Content-Length: 103
Content-Type: application/json; charset=utf-8
Date: Thu, 01 May 2025 14:50:17 GMT
Server: kong/3.10.0.1-enterprise-edition
X-Kong-Request-Id: 108134052a77553f758cf668b90e4c1d
X-Kong-Response-Latency: 0

{
    "message": "no Route matched with those values",
    "request_id": "108134052a77553f758cf668b90e4c1d"
}
```

## まとめ

この記事では、Kong KonnectのData PlaneをAWS ECS（Fargate）上で動かすことで、**最小構成でAPI Gateway環境を構築**する方法を紹介しました。

- **軽量・省リソース**  
  Fargateの設定は `CPU: 512` / `Memory: 1024` の最小構成でも動作可能
  Konnect利用のため外部DB不要
  
- **構築が簡単**  
  複雑なネットワーク設定やLB構成不要。  
  Konnect側で発行される `docker run` コマンドを元に、ECS Task Definition をコピー＆修正するだけ

- **SaaS連携で管理不要**  
  Konnect（SaaS）上でAPIのルーティングやセキュリティを一括管理。  
  データプレーン側は単純なリバースプロキシとして起動すればOK

Kong KonnectとAWS Fargateの組み合わせは、インフラ構築に手間をかけずにAPI Gatewayを試したい方に最適です。データベースやロードバランサの構成が不要で、SaaS型の管理機能とマネージドな実行環境により、最小限の構成で手軽に始められます。シンプルに導入でき、スケールにも対応できる柔軟な構成です。

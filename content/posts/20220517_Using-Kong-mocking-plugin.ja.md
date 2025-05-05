---
title: "Kongの Mocking Plugingを使ってみる"
date: 2022-05-17T13:58:39+09:00
draft: false
tags: 
- Kong Gateway
- Mocking
- Plugin
---
## 紹介

 Mockingプラグインは、開発中のAPIに対するテストを行うために、模擬のエンドポイントを提供するものです。Open API（OAS）仕様に基づいて、APIに送信されたリクエストに模擬応答をレスポンスします。また、テストの柔軟性のため、Mockingプラグインを簡単に有効または無効にすることができます。
<https://docs.konghq.com/hub/kong-inc/mocking/>

注意点として、このプラグインは、200、201と204の応答をレスポンスすることができます。正常動作をテストするために開発されたもので、200番台以外のコードをを返すことができません。

今回は、db-less環境のKong-gatewayをDocker containerで構築し、その上に Mocking Pluginを試してみます。

## Kong-gatewayをデプロイする前に

db-lessの環境のため、Admin APIやGUIで設定を変更することはできません（保存先はないから）。そのため、起動時にDeclarative Configurationという名の設定ファイルを事前にコンテナーに食わせる必要があります。

<https://docs.konghq.com/gateway/2.8.x/reference/db-less-and-declarative-config/#main>

今回の目標は Mockingを試したいので、 Mockingの設定内容も事前にこのファイルに記述していきます。Mocking Pluginの[紹介ページ](https://docs.konghq.com/hub/kong-inc/mocking/#stock-spec)で書いたように、設定自体はとてもシンプルです。ただ、肝心なのはapi_specificationとapi_specification_filenameの二つです。この二つのパラメータは、模擬のエンドポイントのスペック内容を定義するために使われますが、違いは以下の通りです。

- `api_specification_filename`: スペック内容が保存されたファイル名を設定する。
- `api_specification`: スペック内容をそのままパラメータに設定する。

`api_specification_filename`は、設定するファイルを事前にDev Portalにアップロードしてから、パスなしで設定してください。設定の例は[ここ](https://docs.konghq.com/hub/kong-inc/mocking/#deploy-spec-portal)に書いています。しかし、今回はdb-lessの環境を構築するため、そもそもdev protalが利用できないし、api_specification_filenameを利用できません。

そのため、`api_specification`にサンプルのAPIのスペック内容をそのまま設定し、コンテナーを立ち上げます。スペックのサンプルは、Mocking Pluginの[紹介ページ](https://docs.konghq.com/hub/kong-inc/mocking/#stock-spec)にあります。

```yaml kong.conf
_format_version: "1.1"
_transform: true

services:
- host: mockbin.org
  name: example_service
  port: 80
  protocol: http
  routes:
  - name: example_route
    paths:
    - /mock
    strip_path: true
  plugins:
  - name: mocking
    config:
      api_specification: '{"swagger":"2.0","info":{"title":"Stock API","description":"Stock Information Service","version":"0.1"},"host":"127.0.0.1:8000","basePath":"/","schemes":["http","https"],"consumes":["application/json"],"produces":["application/json"],"paths":{"/stock/historical":{"get":{"description":"","operationId":"GET /stock/historical","produces":["application/json"],"tags":["Production"],"parameters":[{"required":true,"in":"query","name":"tickers","type":"string"}],"responses":{"200":{"description":"Status 200","examples":{"application/json":{"meta_data":{"api_name":"historical_stock_price_v2","num_total_data_points":1,"credit_cost":10,"start_date":"yesterday","end_date":"yesterday"},"result_data":{"AAPL":[{"date":"2000-04-23","volume":33,"high":100.75,"low":100.87,"adj_close":275.03,"close":100.03,"open":100.87}]}}}}}}},"/stock/closing":{"get":{"description":"","operationId":"GET /stock/closing","produces":["application/json"],"tags":["Beta"],"parameters":[{"required":true,"in":"query","name":"tickers","type":"string"}],"responses":{"200":{"description":"Status 200","examples":{"application/json":{"meta_data":{"api_name":"closing_stock_price_v1"},"result_data":{"AAPL":[{"date":"2000-06-23","volume":33,"high":100.75,"low":100.87,"adj_close":275.03,"close":100.03,"open":100.87}]}}}}}}}}}'
      max_delay_time: 1
      min_delay_time: 0.001
      random_delay: false
```

## db-lessのKong-gateway環境を構築

ライセンスを環境変数に設定した後、以下のコマンドでコンテナーを立ち上げます。`KONG_DATABASE`が`off`になっているところと、`KONG_DECLARATIVE_CONFIG`に設定ファイルのパスが書かれているところが重要です。設定ファイルは、`-v`でローカルからMountされています。

``` bash
$ docker run -d --name kong-dbless \
  --network=kong-net \
  -v "$(pwd):/kong/declarative/" \
  -e "KONG_DATABASE=off" \
  -e "KONG_DECLARATIVE_CONFIG=/kong/declarative/kong.yaml" \
  -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
  -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
  -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
  -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
  -e "KONG_ADMIN_LISTEN=0.0.0.0:8001" \
  -e "KONG_ADMIN_GUI_URL=http://35.74.69.178:8002" \
  -e KONG_LICENSE_DATA \
  -p 8000:8000 \
  -p 8443:8443 \
  -p 8001:8001 \
  -p 8444:8444 \
  -p 8002:8002 \
  -p 8445:8445 \
  -p 8003:8003 \
  -p 8004:8004 \
  kong/kong-gateway:2.8.1.0-alpine

$ docker ps
CONTAINER ID   IMAGE                              COMMAND                  CREATED          STATUS                    PORTS                                                                                                                                         NAMES
28917c9510f8   kong/kong-gateway:2.8.1.0-alpine   "/docker-entrypoint.…"   18 seconds ago   Up 17 seconds (healthy)   0.0.0.0:8000-8004->8000-8004/tcp, :::8000-8004->8000-8004/tcp, 0.0.0.0:8443-8445->8443-8445/tcp, :::8443-8445->8443-8445/tcp, 8446-8447/tcp   kong-dbless
```

## 検証

Mocking Pluginのスペックに書いたパスを指定すれば、backendのサービスではなく、このスペックに定義した内容がResponseされていました。これでMocking Pluginが有効に働いていることが検証できました。

``` json
$ http :8000/mock/stock/historical
HTTP/1.1 200 OK
Connection: keep-alive
Content-Length: 279
Content-Type: application/json; charset=utf-8
Date: Mon, 23 May 2022 05:18:16 GMT
Server: kong/2.8.1.0-enterprise-edition
X-Kong-Mocking-Plugin: true
X-Kong-Response-Latency: 1

{
    "meta_data": {
        "api_name": "historical_stock_price_v2",
        "credit_cost": 10,
        "end_date": "yesterday",
        "num_total_data_points": 1,
        "start_date": "yesterday"
    },
    "result_data": {
        "AAPL": [
            {
                "adj_close": 275.03,
                "close": 100.03,
                "date": "2000-04-23",
                "high": 100.75,
                "low": 100.87,
                "open": 100.87,
                "volume": 33
            }
        ]
    }
}


$ http :8000/mock/stock/closing
HTTP/1.1 200 OK
Connection: keep-alive
Content-Length: 185
Content-Type: application/json; charset=utf-8
Date: Mon, 23 May 2022 05:20:52 GMT
Server: kong/2.8.1.0-enterprise-edition
X-Kong-Mocking-Plugin: true
X-Kong-Response-Latency: 0

{
    "meta_data": {
        "api_name": "closing_stock_price_v1"
    },
    "result_data": {
        "AAPL": [
            {
                "adj_close": 275.03,
                "close": 100.03,
                "date": "2000-06-23",
                "high": 100.75,
                "low": 100.87,
                "open": 100.87,
                "volume": 33
            }
        ]
    }
}
```

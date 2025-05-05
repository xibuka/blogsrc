---
title: "试用 Kong 的 Mocking 插件"
date: 2022-05-17T13:58:39+09:00
draft: false
tags: 
- Kong Gateway
- Mocking
- Plugin
---
## 介绍

Mocking 插件为开发中的 API 提供模拟端点，便于测试。它基于 Open API（OAS）规范，对发送到 API 的请求返回模拟响应。为了测试的灵活性，Mocking 插件可以很方便地启用或禁用。
<https://docs.konghq.com/hub/kong-inc/mocking/>

注意：该插件只能返回 200、201 和 204 响应。它是为测试正常流程而设计，无法返回 200 以外的状态码。

本文将以 Docker 容器方式搭建 db-less 的 Kong Gateway 环境，并在其上试用 Mocking 插件。

## 部署 Kong Gateway 之前

由于是 db-less 环境，无法通过 Admin API 或 GUI 修改配置（因为没有存储位置）。因此，启动容器时需要提前准备好名为 Declarative Configuration 的配置文件。

<https://docs.konghq.com/gateway/2.8.x/reference/db-less-and-declarative-config/#main>

本次的目标是试用 Mocking，所以也要在该文件中写好 Mocking 的相关配置。正如 [Mocking 插件介绍页面](https://docs.konghq.com/hub/kong-inc/mocking/#stock-spec) 所述，配置本身非常简单，关键参数有 `api_specification` 和 `api_specification_filename`：

- `api_specification_filename`：指定保存规范内容的文件名。
- `api_specification`：直接将规范内容作为参数写入。

如果用 `api_specification_filename`，需要提前将文件上传到 Dev Portal，并且只写文件名，不带路径。示例见[这里](https://docs.konghq.com/hub/kong-inc/mocking/#deploy-spec-portal)。但本次我们用 db-less 环境，无法使用 Dev Portal，因此不能用 `api_specification_filename`。

所以我们直接在 `api_specification` 里写入 API 规范的示例内容，然后启动容器。规范示例可参考 [Mocking 插件介绍页面](https://docs.konghq.com/hub/kong-inc/mocking/#stock-spec)。

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

## 构建 db-less 的 Kong Gateway 环境

设置好许可证环境变量后，使用如下命令启动容器。关键点在于 `KONG_DATABASE=off` 以及 `KONG_DECLARATIVE_CONFIG` 的配置文件路径。配置文件通过 `-v` 从本地挂载。

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

## 验证

只要访问 Mocking 插件规范中定义的路径，返回的就是规范中定义的内容，而不是后端服务的响应。这样就能确认 Mocking 插件已生效。

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

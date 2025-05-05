---
title: "Trying Out Kong's Mocking Plugin"
date: 2022-05-17T13:58:39+09:00
draft: false
tags: 
- Kong Gateway
- Mocking
- Plugin
---
## Introduction

The Mocking plugin provides mock endpoints for testing APIs under development. Based on the Open API (OAS) specification, it returns mock responses to requests sent to the API. For flexibility in testing, the Mocking plugin can be easily enabled or disabled.
<https://docs.konghq.com/hub/kong-inc/mocking/>

Note: This plugin can only return 200, 201, and 204 responses. It is designed for testing normal operations and cannot return codes outside the 200 range.

In this article, we'll build a db-less Kong Gateway environment using a Docker container and try out the Mocking Plugin on it.

## Before Deploying Kong Gateway

Since this is a db-less environment, you cannot change settings via the Admin API or GUI (because there is no place to save them). Therefore, you need to provide a configuration file called Declarative Configuration to the container at startup.

<https://docs.konghq.com/gateway/2.8.x/reference/db-less-and-declarative-config/#main>

Our goal is to try out Mocking, so we'll also include the Mocking configuration in this file. As described on the [Mocking Plugin introduction page](https://docs.konghq.com/hub/kong-inc/mocking/#stock-spec), the configuration itself is very simple. The key parameters are `api_specification` and `api_specification_filename`:

- `api_specification_filename`: Set the filename where the spec is saved.
- `api_specification`: Set the spec content directly as a parameter.

For `api_specification_filename`, upload the file to the Dev Portal in advance and set the filename without a path. See [here](https://docs.konghq.com/hub/kong-inc/mocking/#deploy-spec-portal) for an example. However, since we're building a db-less environment, the Dev Portal is not available, so we can't use `api_specification_filename`.

Therefore, we'll set a sample API spec directly in `api_specification` and start the container. You can find a sample spec on the [Mocking Plugin introduction page](https://docs.konghq.com/hub/kong-inc/mocking/#stock-spec).

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

## Building a db-less Kong Gateway Environment

After setting the license as an environment variable, start the container with the following command. The important parts are `KONG_DATABASE=off` and the path to the config file in `KONG_DECLARATIVE_CONFIG`. The config file is mounted from the local machine using `-v`.

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

## Verification

If you specify the path described in the Mocking Plugin spec, the response will be returned as defined in the spec, not from the backend service. This confirms that the Mocking Plugin is working as expected.

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

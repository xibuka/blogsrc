---
title: "Accessing and Managing GraphQL APIs with Kong Gateway"
date: 2025-03-25T23:49:19+09:00
draft: false
tags:
- kong
- GraphQL
---

## Review of GraphQL

GraphQL is an API query language developed by Facebook that provides a more flexible way to retrieve data compared to traditional REST APIs.

### Features of GraphQL

- **Single Endpoint**: While REST APIs require multiple endpoints, GraphQL allows you to send different queries to a single endpoint (`/graphql`).
- **Fetch Only Needed Data**: Clients can specify only the fields they need, preventing unnecessary data transfer.
- **Type System**: The API schema is defined with types, making the data structure clear.

For example, to retrieve information about Japan from the GraphQL API at `https://countries.trevorblades.com/`, you can send the following query:

```graphql
{
  country(code: "JP") {
    name
    capital
    currency
  }
}
```

To execute this query using `curl`:

```sh
curl -X POST https://countries.trevorblades.com/ \
  -H "Content-Type: application/json" \
  -d '{"query": "{ country(code: \"JP\") { name capital currency } }"}'
```

Response:

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

A powerful aspect of GraphQL is the ability to flexibly adjust the data you retrieve by changing the query. For example, if you remove `capital` from the above query:

```sh
curl -X POST https://countries.trevorblades.com/ \
  -H "Content-Type: application/json" \
  -d '{"query": "{ country(code: \"JP\") { name currency } }"}'
```

The response will no longer include `capital`:

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

This way, you can dynamically change the type of data you want to retrieve.

### Disadvantages of GraphQL

- **Complexity**: Clients need to design queries, which increases the learning curve compared to simple REST APIs.
- **Difficult to Cache**: REST APIs are easy to cache based on URLs, but GraphQL mainly uses POST requests, making caching strategies more complex.
- **Load Issues**: If clients send complex queries, the server's processing load can increase.

## Overview of Kong

Kong is an open-source API gateway that handles API management, authentication, routing, load balancing, and more.

### Roles of Kong

- **API Management**: Publish, authenticate, restrict, and monitor APIs
- **Extensible with Plugins**: Use plugins for authentication, caching, rate limiting, transformation, and more
- **Load Balancing and Scalability**: Appropriately distribute requests to multiple backend services

Kong can manage not only RESTful API requests but also GraphQL API requests. GraphQL is known for its flexibility and efficient data retrieval, and Kong is a useful tool for operating such APIs in practice.

### GraphQL-Related Plugins Available in Kong

- DeGraphQL: A plugin that converts GraphQL APIs to be used like RESTful APIs
- GraphQL Caching: A plugin that caches GraphQL responses to reduce processing load for identical requests
- GraphQL Rate Limiting: A plugin that limits the number of requests to GraphQL APIs

## Introduction to the DeGraphQL Plugin

The **DeGraphQL** plugin allows you to treat GraphQL as if it were a RESTful API in Kong.

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/f028b415-adbe-46f8-bd0d-09f198da8de5.png)

### Main Features

- Converts requests to GraphQL APIs into REST format
- Clients no longer need to write GraphQL queries
- Usable with existing REST API clients and tools

This makes it easy for developers unfamiliar with GraphQL to retrieve data.

---

### Demo: Accessing GraphQL Like RESTful APIs with Kong

#### Creating a Service and Route

First, create a Service pointing to the GraphQL endpoint and define a corresponding Route.

```sh
# Create Service
curl -i -X POST http://localhost:8001/services \
  --data "name=countries-graphql" \
  --data "url=https://countries.trevorblades.com/"

# Create Route
curl -i -X POST http://localhost:8001/routes \
  --data "service.name=countries-graphql" \
  --data "paths[]=/dql"
```

#### Enabling the DeGraphQL Plugin

Next, enable the DeGraphQL plugin for the Service. Note that this plugin can only be created at the **Service layer**.

```sh
curl -X POST http://localhost:8001/services/countries-graphql/plugins \
    --data name="degraphql"
```

#### DeGraphQL Route Configuration

Finally, create DeGraphQL Routes to set the content of the GraphQL query.

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

### Accessing via Kong as if RESTful

Once set up, you can try accessing through Kong as if it were a REST API.

```sh
curl -X GET http://localhost:8000/dql/JP
```

This request will return a response like the following:

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

This demo introduced how to use the DeGraphQL plugin in Kong to utilize GraphQL APIs as REST APIs.

### Benefits

- Developers unfamiliar with GraphQL can access it as a simple REST API
- Existing REST clients can be used as-is
- Flexible routing is possible by leveraging Kong as an API gateway

## Introduction to GraphQL Proxy Caching Advanced

GraphQL Proxy Caching Advanced is a plugin that enhances caching for GraphQL APIs in Kong. It caches GraphQL responses to prevent recalculation for identical requests, improving performance.

### Main Features

- **Request Caching**: Applies cache to identical queries, reducing backend load
- **Cache Expiry Setting**: Set TTL (Time-To-Live) to keep cache for an appropriate period
- **Cache Bypass**: Exclude specific requests from caching as needed

### Demo of GraphQL Proxy Caching Advanced

#### Enabling the Plugin

First, enable GraphQL Proxy Caching Advanced for the target Service.

```sh
curl -X POST http://localhost:8001/services/countries-graphql/plugins \
  --data name="graphql-proxy-cache-advanced" \
  --data config.strategy="memory" \
  --data config.cache_ttl=300
```

This sets the cache strategy to memory and the cache TTL to 300 seconds (5 minutes). You can also use Redis as the cache strategy.

#### Checking Cache Operation

First request (no cache):

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

The first request is sent to the backend GraphQL API and returns a response. Since there is no cache yet, `X-Cache-Status: Miss` is shown, and the latency is 174ms as indicated by `< X-Kong-Upstream-Latency: 174`.

If you send the same request again:

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

As shown by `X-Cache-Status: Hit`, the cache is now effective and the response is returned directly from Kong. Also, `< X-Kong-Upstream-Latency: 0` means there was no access to the upstream API, so latency is 0ms.

#### Cache Operations

You can use the API endpoints provided by this plugin to check and delete cache. For details, see `https://docs.konghq.com/hub/kong-inc/graphql-proxy-cache-advanced/api/#managing-cache-entities`.

By using GraphQL Proxy Caching Advanced, you can improve the performance of your GraphQL APIs.

- **Request caching enables faster responses and reduces backend load**
- **By setting appropriate cache strategies and TTL, you can balance data freshness and performance**
- **Bypassing and clearing cache allows flexible cache management**

## Introduction to GraphQL Rate Limiting Advanced

GraphQL Rate Limiting Advanced is a plugin that enhances request limiting for GraphQL APIs in Kong. This plugin helps prevent excessive requests and reduces load on API services.

### Main Features

- **Request Limiting**: Restrict the number of requests in a specific time period to prevent service overload
- **Per-User Limiting**: Set limits for each user to accommodate individual usage
- **Dynamic Limit Settings**: Flexibly adjust request limits

### Demo of GraphQL Rate Limiting Advanced

#### Enabling the Plugin

First, enable GraphQL Rate Limiting Advanced for the target Service.

```bash
curl -i -X POST http://localhost:8001/services/countries-graphql/plugins \
  --data name=graphql-rate-limiting-advanced \
  --data config.limit=3,100 \
  --data config.window_size=60,3600 \
  --data config.sync_rate=1
```

This configuration allows up to 3 requests per minute and up to 100 requests per hour.

## Conclusion

By using Kong, you can manage GraphQL APIs more efficiently and improve security and performance. With the DeGraphQL plugin, you can treat GraphQL as RESTful, and with rate limiting and caching, you can manage load and improve API availability while reducing operational overhead.

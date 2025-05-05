---
title: "Trying Out Kong Gateway's Plugin Ordering Feature"
date: 2023-01-27T11:42:28+09:00
draft: false
tags: 
- Kong Gateway
- plugin
---
While working on a PoC with Kong Gateway, I encountered an issue.
The PoC requirements were as follows:

- Protect the entire Gateway with the Key-auth plugin
- Use the Request-transformer plugin to add the required API Key to the header and pass authentication

After configuring both plugins, even if the API key was added to the request, authentication still failed.

``` bash
# key-auth is enabled
❯ http --header localhost:8000/demo | head -1
HTTP/1.1 401 Unauthorized

# Got 401 after creating request-transformer-adv plugin.
❯ curl -X POST http://localhost:8001/services/testsvc/plugins \
    --data "name=request-transformer-advanced"  \
    --data "config.add.headers=apikey:wenhandemo"
...
❯ http --header localhost:8000/demo | head -1
HTTP/1.1 401 Unauthorized
```

After investigating, I found that plugins have a default execution order.

[https://docs.konghq.com/gateway/latest/plugin-development/custom-logic/#plugins-execution-order](https://docs.konghq.com/gateway/latest/plugin-development/custom-logic/#plugins-execution-order)

The priority of key-auth is `1250`, which is higher than that of request-transformer-adv (`801`). Therefore, when key-auth runs, the required API Key has not yet been added to the header.

To solve this, you can use the plugin ordering feature newly added in Kong Gateway 3.0 to explicitly specify the execution order of plugins.

[https://docs.konghq.com/gateway/3.0.x/kong-enterprise/plugin-ordering/get-started/](https://docs.konghq.com/gateway/3.0.x/kong-enterprise/plugin-ordering/get-started/)

Let's implement this. When configuring the `request-transformer-advanced` plugin, declare that it should run before `key-auth`.

```bash
❯ curl -X POST http://localhost:8001/services/testsvc/plugins \
    --data "name=request-transformer-advanced"  \
    --data "config.add.headers=apikey:wenhandemo" \
    --data "ordering.before.access=key-auth"
...
❯ http --header localhost:8000/demo | head -1
HTTP/1.1 200 OK
```

Ta-da!

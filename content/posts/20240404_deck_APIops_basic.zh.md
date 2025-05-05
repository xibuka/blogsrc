---
title: "用 decK CLI 配置 Kong API Gateway"
date: 2024-04-04T23:49:19+09:00
draft: false
tags:
- decK
- Kong Gateway
- APIOps
---

## Deck CLI

decK 是为 API 生命周期自动化（APIOps）开发的命令行工具。开发和运维团队可以用它从开发到部署全流程管理 API，确保 API 集成的一致性、可靠性和速度。

decK 命令具备以下功能和特点：

- 导出（备份）
  将现有 Kong 配置导出为 YAML 格式的配置文件

- 导入（还原）
  使用导出的或手写的配置文件应用到 Kong 配置

- 差异和同步
  decK 可以比较文件中的配置和 Kong 数据库中的配置，并进行同步，也可以检测配置差异
  
- 反向同步
  如果 Kong 数据库中有而文件中没有的配置，也可以反向同步到文件

- 校验
  校验配置文件的语法错误

- 重置
  删除 Kong 数据库中的所有实体

- 并发操作
  对 Kong Admin API 的调用会并发执行，利用多线程加速同步过程

- Kong 认证
  通过 `--headers Kong-Admin-Token:test` 这种方式在 HTTP 头中加入认证信息，可访问需要认证的 Kong

- 多文件管理 Kong 配置
  可以根据实体间共享的一组标签，将 Kong 配置拆分为多个文件管理

- 配置管理自动化
  decK 设计为 CI 流水线的一部分，不仅能推送配置到 Kong，还能检测配置漂移

下面按子命令举例说明

## 事前准备

以下 Kong 配置文件为基础示例。包含一个 Service 和一个 Route。

``` kong.yaml
_format_version: "3.0"
services:
- host: httpbin.org
  name: uuid-generator
  path: /
  protocol: http
  routes:
  - name: uuid-generator
    paths:
    - ~/uuid$
    strip_path: false
```

## deck gateway 相关

### deck gateway ping

首先用 ping 检查连通性

```bash
deck gateway ping --headers Kong-Admin-Token:test
Successfully connected to Kong!
Kong version:  3.4.3.5
```

如果不指定 Kong Admin API 的地址，默认会连接到 `localhost:8001`。
如需检查非本地 Kong 的连通性，用 `--kong-addr` 指定地址。

```bash
deck gateway ping --kong-addr http://18.178.66.113:8001 --headers Kong-Admin-Token:test
Successfully connected to Kong!
Kong version:  3.4.3.5
```

### deck gateway validate

校验配置文件语法。无问题时无输出，有语法错误会显示行号和错误内容。
该命令会连接 Kong Admin API 进行校验，耗时较长但能发现严重错误。如只需本地校验可用 `deck file validate`。
校验过程中不会修改 Kong 数据库。

```bash
deck gateway validate kong.yaml --headers Kong-Admin-Token:test
Error: 1 errors occurred:
  reading file kong.yaml: validating file content: unmarshaling file content: error converting YAML to JSON: yaml: line 7: could not find expected ':'
```

### deck gateway sync

将上述配置文件应用到 Kong Gateway。默认从标准输入读取配置。

```bash
$ cat kong.yaml | deck gateway sync --headers Kong-Admin-Token:test
creating service uuid-generator
creating route uuid-generator
Summary:
  Created: 2
  Updated: 0
  Deleted: 0
```

### deck gateway diff

更新文件后，执行 `deck gateway diff`，检查 Kong 数据库和文件配置的差异。

```bash
$ sed -i 's/protocol: http/protocol: https/g' kong.yaml
$ deck gateway diff kong.yaml --headers Kong-Admin-Token:test
updating service uuid-generator  {
   "connect_timeout": 60000,
   "enabled": true,
   "host": "httpbin.org",
   "id": "033e20b1-9a83-4f80-a75e-ee4f9b354676",
   "name": "uuid-generator",
   "path": "/",
   "port": 80,
-  "protocol": "http",
+  "protocol": "https",
   "read_timeout": 60000,
   "retries": 5,
   "write_timeout": 60000
 }

Summary:
  Created: 0
  Updated: 1
  Deleted: 0

```

如需应用文件配置，再次执行 deck gateway sync。

### deck gateway dump

如需将数据库配置反映到文件或做备份，可用 dump。
之后再 diff 一次确认数据库配置已写入文件。

```bash
$ deck gateway dump -o kong.yaml --headers Kong-Admin-Token:test
File 'kong.yaml' already exists. Do you want to overwrite it? yes

$ deck gateway diff kong.yaml --headers Kong-Admin-Token:test
Summary:
  Created: 0
  Updated: 0
  Deleted: 0
```

### deck gateway reset

删除 Kong 数据库中的所有配置。

```bash
deck gateway reset --headers Kong-Admin-Token:test
This will delete all configuration from Kong's database.
> Are you sure? yes
deleting route uuid-generator
deleting service uuid-generator
Summary:
  Created: 0
  Updated: 0
  Deleted: 2
```

## deck file 相关

deck file 主要处理 Kong 配置文件相关操作。

### deck file validate

类似 `deck gateway validate`，但只校验本地文件语法，不与 Kong Admin API 通信，速度更快。

```bash
deck file validate kong.yaml
Error: 1 errors occurred:
  reading file kong.yaml: validating file content: unmarshaling file content: error converting YAML to JSON: yaml: line 7: could not find expected ':'

```

### deck file kong2kic

将 Kong 配置文件转换为 Kubernetes 可用格式。
例如，以下 kong.yaml 配置文件：

```kong.yaml
_format_version: "3.0"
services:
- connect_timeout: 60000
  enabled: true
  host: httpbin.org
  name: uuid-generator
  path: /
  port: 80
  protocol: http
  read_timeout: 60000
  retries: 5
  routes:
  - https_redirect_status_code: 426
    name: uuid-generator
    path_handling: v0
    paths:
    - ~/uuid$
    preserve_host: false
    protocols:
    - http
    - https
    regex_priority: 0
    request_buffering: true
    response_buffering: true
    strip_path: false
  write_timeout: 60000
```

#### HTTPRoute + Service（默认）

要生成 HTTPRoute + Service 资源，执行以下命令：

```bash
deck file kong2kic -s kong.yaml
```

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  annotations:
    konghq.com/https-redirect-status-code: "426"
    konghq.com/path-handling: v0
    konghq.com/preserve-host: "false"
    konghq.com/regex-priority: "0"
    konghq.com/request-buffering: "true"
    konghq.com/response-buffering: "true"
    konghq.com/strip-path: "false"
  name: uuid-generator-uuid-generator
spec:
  parentRefs:
  - name: kong
---
apiVersion: v1
kind: Service
metadata:
  annotations:
    konghq.com/connect-timeout: "60000"
    konghq.com/path: /
    konghq.com/protocol: http
    konghq.com/read-timeout: "60000"
    konghq.com/retries: "5"
    konghq.com/write-timeout: "60000"
  name: uuid-generator
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: uuid-generator
---
```

#### Ingress + Service

如需生成 Ingress + Service 资源，加 --ingress 参数再执行命令。

```bash
deck file kong2kic -s kong.yaml --ingress
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    konghq.com/https-redirect-status-code: "426"
    konghq.com/path-handling: v0
    konghq.com/preserve-host: "false"
    konghq.com/protocols: http,https
    konghq.com/regex-priority: "0"
    konghq.com/request-buffering: "true"
    konghq.com/response-buffering: "true"
    konghq.com/strip-path: "false"
  name: uuid-generator-uuid-generator
spec:
  ingressClassName: kong
  rules:
  - http:
      paths:
      - backend:
          service:
            name: uuid-generator
            port:
              number: 80
        path: /~/uuid$
        pathType: ImplementationSpecific
---
apiVersion: v1
kind: Service
metadata:
  annotations:
    konghq.com/connect-timeout: "60000"
    konghq.com/path: /
    konghq.com/protocol: http
    konghq.com/read-timeout: "60000"
    konghq.com/retries: "5"
    konghq.com/write-timeout: "60000"
  name: uuid-generator
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: uuid-generator
---
```

### deck file openapi2kong

将 OpenAPI 规范（OAS）转换为 Kong 配置文件。
例如，以下 OAS 文件不仅包含 Service 和 Route，还有 Plugin。

```yaml
openapi: 3.0.0
tags:
  - description: Creates a random UUID and returns it in a JSON structure
    name: Generate UUID
  - description: Returns a delayed response (max of 10 seconds).
    name: Delayed Response
info:
  contact:
    email: wenhan.shi@konghq.com
    url: https://konghq.com/
  description: A simple service returning a UUID based on https://httpbin.org
  title: UUID generator based on httpbin.org
  version: 1.0.8
paths:
  /uuid:
    get:
      operationId: uuid
      summary: Return a UUID.
      description: Return a UUID
      responses:
        "200":
          description: A UUID4.
      tags:
        - Generate UUID
    x-kong-plugin-rate-limiting:
      enabled: true
      config:
        minute: 5
    x-kong-plugin-proxy-cache:
      enabled: true
      config:
        strategy: memory

servers:
  - url: https://httpbin.org/
```

用如下命令一键转换，插件配置也会被正确转换。

```bash
deck file openapi2kong -s openapi.yaml
```

```yaml
_format_version: "3.0"
services:
- host: httpbin.org
  id: 50f943d2-3299-5315-adf6-7da92729c8ce
  name: uuid-generator-based-on-httpbin-org
  path: /
  plugins: []
  port: 443
  protocol: https
  routes:
  - id: c58bf17c-dfd9-544d-965b-cc3e26be87f1
    methods:
    - GET
    name: uuid-generator-based-on-httpbin-org_uuid
    paths:
    - ~/uuid$
    plugins:
    - config:
        strategy: memory
      enabled: true
      id: fc364f07-919d-5fd5-b9fe-ac6540848e4f
      name: proxy-cache
      tags: []
    - config:
        minute: 5
      enabled: true
      id: ff5cb72c-3698-5403-9420-3beb6c2fb26c
      name: rate-limiting
      tags: []
    regex_priority: 200
    strip_path: false
    tags: []
  tags: []
upstreams: []
```

### deck file add-plugins

为 Kong 配置文件添加插件定义。

以如下常见配置为例：

```yaml
_format_version: "3.0"
services:
- host: httpbin.org
  name: uuid-generator
  path: /
  port: 80
  protocol: http
  routes:
  - name: uuid-generator
    paths:
    - ~/uuid$
    strip_path: false
```

执行如下命令，像 `--selector='services[*]'` 这样写，`--config` 定义的插件会加到所有 Service 上。
如果把 `--selector` 改成 `='route[*]'`，插件会加到所有 Route 上。

```bash
cat kong.yaml | deck file add-plugins --selector='services[*]' --config='{"plugins":[{"config":{"strategy":"memory"},"enabled":true,"name":"proxy-cache"}]}'
```

```yaml
_format_version: "3.0"
services:
- host: httpbin.org
  name: uuid-generator
  path: /
  plugins:
  - plugins:
    - config:
        strategy: memory
      enabled: true
      name: proxy-cache
  port: 80
  protocol: http
  routes:
  - name: uuid-generator
    paths:
    - ~/uuid$
    strip_path: false
```

上述方法中，`--selector` 和 `--config` 都写在命令行上，命令会很长。
也可以把这两个参数保存到文件再应用。例如如下内容保存为 JSON 文件：

```proxy-cache.json
{ "_format_version": "1.0",
 "add-plugins": [
   { "selectors": [
      "service[*]"
     ],
     "overwrite": false,
     "plugins": [
       { "name": "proxy-cache",
         "config": {
           "strategy": "memory"
         }
       }
      ]
   }
 ]
}
```

然后 add-plugins 后面加这个文件，STDIN 里的配置内容会被追加插件。

```bash
cat kong.yaml | deck file add-plugins proxy-cache.json
```

```yaml
_format_version: "3.0"
services:
- host: httpbin.org
  name: uuid-generator
  path: /
  plugins:
  - config:
      strategy: memory
    name: proxy-cache
  port: 80
  protocol: http
  routes:
  - name: uuid-generator
    paths:
    - ~/uuid$
    strip_path: false
```

还有更多子命令，前半部分先介绍到这里。

- deck file add-tags - 给 decK 文件中的对象添加标签
- deck file convert - 不同格式文件互转
- deck file lint - 按规则集校验文件
- deck file list-tags - 列出 decK 文件中对象的标签
- deck file merge - 合并多个 decK 文件
- deck file namespace - 路由路径加前缀实现命名空间
- deck file patch - 给 decK 文件打补丁
- deck file remove-tags - 移除 decK 文件对象的标签
- deck file render - 合并多个完整配置文件渲染为一个 Kong 声明式配置文件。

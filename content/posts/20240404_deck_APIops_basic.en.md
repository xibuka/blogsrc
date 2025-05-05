---
title: "Configuring Kong API Gateway with decK CLI"
date: 2024-04-04T23:49:19+09:00
draft: false
tags:
- decK
- Kong Gateway
- APIOps
---

## Deck CLI

decK is a command-line tool developed for API lifecycle automation (APIOps). It allows developers and operations teams to manage APIs from development to deployment, ensuring consistency, reliability, and speed in API integration.

decK commands have the following features and characteristics:

- Export (Backup)
  Export existing Kong configuration to a YAML configuration file

- Import (Restore)
  Apply Kong configuration using exported or hand-written configuration files

- Diff and Sync
  decK can compare the configuration in the file with the configuration in Kong's DB and synchronize them. It can also detect configuration differences
  
- Reverse Sync
  If there is a configuration in Kong's DB that is not in the file, it can also sync back to the file

- Validation
  Validate configuration file syntax errors

- Reset
  Delete all entities in Kong's database

- Parallel Operations
  Calls to Kong's Admin API are executed in parallel, using multiple threads to speed up the sync process

- Authentication with Kong
  You can access Kong that requires authentication by adding authentication information to the HTTP header in the form `--headers Kong-Admin-Token:test`

- Manage Kong configuration with multiple files
  You can split Kong configuration into multiple files based on a set of shared tags between entities

- Automated configuration management
  decK is designed as part of a CI pipeline, not only pushing configuration to Kong but also detecting configuration drift

Below are examples for each subcommand

## Preparation

The following Kong configuration file is used as a base. There is one Service and one Route.

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

## deck gateway related

### deck gateway ping

First, check connectivity with ping

```bash
deck gateway ping --headers Kong-Admin-Token:test
Successfully connected to Kong!
Kong version:  3.4.3.5
```

If you do not specify the location of Kong's Admin API, it will connect to `localhost:8001` by default.
If you want to check connectivity to a non-local Kong, specify the address with `--kong-addr`.

```bash
deck gateway ping --kong-addr http://18.178.66.113:8001 --headers Kong-Admin-Token:test
Successfully connected to Kong!
Kong version:  3.4.3.5
```

### deck gateway validate

Check the syntax of the configuration file. If there are no problems, nothing is output, but if there is a syntax error, the line number and error details are displayed.
This command connects to the Kong Admin API for validation. It takes some time, but can catch serious errors. If you only want to validate a local file, use `deck file validate`.
No changes are made to Kong's DB during validation.

```bash
deck gateway validate kong.yaml --headers Kong-Admin-Token:test
Error: 1 errors occurred:
  reading file kong.yaml: validating file content: unmarshaling file content: error converting YAML to JSON: yaml: line 7: could not find expected ':'
```

### deck gateway sync

Apply the above configuration file to Kong Gateway. By default, it reads the configuration from standard input.

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

After updating the file, run `deck gateway diff` to check the difference between the configuration in Kong's DB and the file.

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

If you want to apply the file configuration, run `deck gateway sync` again.

### deck gateway dump

If you want to reflect the configuration in the DB back to the file, or take a backup, use dump.
After that, run diff again to confirm that the DB configuration has been reflected in the file.

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

Delete all configuration in Kong's DB.

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

## deck file related

deck file mainly handles operations related to Kong configuration files.

### deck file validate

Similar to `deck gateway validate`, but only checks local file syntax without communicating with the Kong Admin API, so it is faster.

```bash
deck file validate kong.yaml
Error: 1 errors occurred:
  reading file kong.yaml: validating file content: unmarshaling file content: error converting YAML to JSON: yaml: line 7: could not find expected ':'

```

### deck file kong2kic

Convert Kong configuration files for use with Kubernetes.
For example, using the following kong.yaml configuration file:

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

#### HTTPRoute + Service (Default)

To generate HTTPRoute + Service resources, run the following command:

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

To generate Ingress + Service resources, add the --ingress option and run the command.

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

Convert OpenAPI specifications (OAS) to Kong configuration files.
For example, using the following OAS file, which includes not only Service and Route but also Plugin.

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

You can convert it in one shot with the following command. The plugin settings are also converted properly.

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

Add plugin definitions to a Kong configuration file.

For the usual configuration below:

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

If you run the following command, as written with `--selector='services[*]'`, the plugin defined with `--config` will be added to all Services.
If you change the `--selector` expression to `='route[*]'`, the plugin will be added to all Routes.

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

With the above method, since `--selector` and `--config` are all written on the command line, the command itself becomes long.
You can also save these two parameters to a file and apply them. For example, save the following content to a JSON file:

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

Then, add this file after add-plugins, and the plugin will be appended to the configuration content from STDIN.

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

There are still more subcommands, but I'll stop here for the first half.

- deck file add-tags - Add tags to objects in a decK file
- deck file convert - Convert files from one format into another format
- deck file lint - Validate a file against a ruleset
- deck file list-tags - List current tags from objects in a decK file
- deck file merge - Merge multiple decK files into one
- deck file namespace - Apply a namespace to routes in a decK file by prefixing the path.
- deck file patch - Apply patches on top of a decK file
- deck file remove-tags - Remove tags from objects in a decK file
- deck file render - Combines multiple complete configuration files and renders them as one Kong declarative config file.

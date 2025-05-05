---
title: "Configuring Kong Gateway with Terraform"
date: 2024-10-08T23:49:19+09:00
draft: false
tags:
- Terraform
- Kong Gateway
---

There is an article on [Building a Konnect Environment with Terraform](https://qiita.com/ipppppei/items/573b90e8c42684653db8), which describes how to set up a Konnect environment using Terraform. In this article, I will leave a memo on how to configure Kong Gateway for an on-premises environment, not Konnect.

The Terraform provider used this time is as follows:

[https://github.com/Kong/terraform-provider-kong-gateway](https://github.com/Kong/terraform-provider-kong-gateway)

[https://registry.terraform.io/providers/Kong/kong-gateway/latest/docs](https://registry.terraform.io/providers/Kong/kong-gateway/latest/docs)

Installation of Kong and Terraform is omitted.

## Minimum Required Files

- Specify the provider and the address of Kong Gateway's Admin API

```provider.tf
terraform {
  required_providers {
    kong-gateway = {
      source = "kong/kong-gateway"
    }
  }
}

provider "kong-gateway" {
  server_url = "http://localhost:8001"
}
```

- Service definition

```service.tf
resource "kong-gateway_service" "httpbin" {
  name     = "HTTPBin"
  protocol = "http"
  host     = "httpbin.org"
  port     = 80
  path     = "/"
}
```

- Route definition, linking the associated Service by ID

```route.tf
resource "kong-gateway_route" "hello" {
  methods = ["GET"]
  name    = "Anything"
  paths   = ["/anything"]

  strip_path = false

  service = {
    id = kong-gateway_service.httpbin.id
  }
}
```

## Applying the Configuration

Kong Gateway's configuration is very lightweight, so the process finishes quickly.

```bash
terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # kong-gateway_route.hello will be created
  + resource "kong-gateway_route" "hello" {
      + created_at                 = (known after apply)
      + destinations               = (known after apply)
      + headers                    = (known after apply)
      + hosts                      = (known after apply)
      + https_redirect_status_code = (known after apply)
      + id                         = (known after apply)
      + methods                    = [
          + "GET",
        ]
      + name                       = "Anything"
      + path_handling              = (known after apply)
      + paths                      = [
          + "/anything",
        ]
      + preserve_host              = (known after apply)
      + protocols                  = (known after apply)
      + regex_priority             = (known after apply)
      + request_buffering          = (known after apply)
      + response_buffering         = (known after apply)
      + service                    = {
          + id = (known after apply)
        }
      + snis                       = (known after apply)
      + sources                    = (known after apply)
      + strip_path                 = false
      + tags                       = (known after apply)
      + updated_at                 = (known after apply)
    }

  # kong-gateway_service.httpbin will be created
  + resource "kong-gateway_service" "httpbin" {
      + ca_certificates    = (known after apply)
      + client_certificate = (known after apply)
      + connect_timeout    = (known after apply)
      + created_at         = (known after apply)
      + enabled            = (known after apply)
      + host               = "httpbin.org"
      + id                 = (known after apply)
      + name               = "HTTPBin"
      + path               = "/"
      + port               = 80
      + protocol           = "http"
      + read_timeout       = (known after apply)
      + retries            = (known after apply)
      + tags               = (known after apply)
      + tls_verify         = (known after apply)
      + tls_verify_depth   = (known after apply)
      + updated_at         = (known after apply)
      + write_timeout      = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

kong-gateway_service.httpbin: Creating...
kong-gateway_service.httpbin: Creation complete after 0s [id=13137290-ba88-432c-a9ea-d10465ffaa8f]
kong-gateway_route.hello: Creating...
kong-gateway_route.hello: Creation complete after 0s [id=152c5f85-cf3b-466a-8d0f-ead33de8f6ca]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

## Operation Check

A new Service and Route have been created

```bash
http :8001/services/13137290-ba88-432c-a9ea-d10465ffaa8f
...

{
    "ca_certificates": null,
    "client_certificate": null,
    "connect_timeout": 60000,
    "created_at": 1728370653,
    "enabled": true,
    "host": "httpbin.org",
    "id": "13137290-ba88-432c-a9ea-d10465ffaa8f",
    "name": "HTTPBin",
    "path": "/",
    "port": 80,
    "protocol": "http",
    "read_timeout": 60000,
    "retries": 5,
    "tags": null,
    "tls_verify": null,
    "tls_verify_depth": null,
    "updated_at": 1728370653,
    "write_timeout": 60000
}


http :8001/routes/152c5f85-cf3b-466a-8d0f-ead33de8f6ca
...

{
    "created_at": 1728370654,
    "destinations": null,
    "headers": null,
    "hosts": null,
    "https_redirect_status_code": 426,
    "id": "152c5f85-cf3b-466a-8d0f-ead33de8f6ca",
    "methods": [
        "GET"
    ],
    "name": "Anything",
    "path_handling": "v0",
    "paths": [
        "/anything"
    ],
    "preserve_host": false,
    "protocols": [
        "http",
        "https"
    ],
    "regex_priority": 0,
    "request_buffering": true,
    "response_buffering": true,
    "service": {
        "id": "13137290-ba88-432c-a9ea-d10465ffaa8f"
    },
    "snis": null,
    "sources": null,
    "strip_path": false,
    "tags": null,
    "updated_at": 1728370654
}
```

Access is also working fine

```bash
http :8000/anything
HTTP/1.1 200 OK
...

{
    "args": {},
    "data": "",
    "files": {},
    "form": {},
    "headers": {
        "Accept": "*/*",
        "Accept-Encoding": "gzip, deflate",
        "Host": "httpbin.org",
        "User-Agent": "HTTPie/2.6.0",
        "X-Amzn-Trace-Id": "Root=1-6704d7fb-33cba6d66cde8b1d7c734b11",
        "X-Forwarded-Host": "localhost",
        "X-Forwarded-Path": "/anything",
        "X-Kong-Request-Id": "7b13371017a1973e83cde51b8d9d1d45"
    },
    "json": null,
    "method": "GET",
    "origin": "172.21.0.1, 18.178.66.113",
    "url": "http://localhost/anything"
}
```

## Adding a Plugin

Let's add a Basic Auth plugin to the Service. The target Service can be specified by ID.

```plugin_basic_auth.tf
resource "kong-gateway_plugin_basic_auth" "my_pluginbasicauth" {
  enabled = true
  service = {
    id = kong-gateway_service.httpbin.id
  }
  protocols = [
    "http"
  ]
}
```

Next, define the Consumer and set the authentication information for the Consumer in the file.

```consumer.tf
resource "kong-gateway_consumer" "alice" {
  username  = "alice"
  custom_id = "alice"
}
```

```basic_auth.tf
resource "kong-gateway_basic_auth" "my_basicauth" {
  username = "alice-test"
  password = "demo"

  consumer = {
    id = kong-gateway_consumer.alice.id
  }
}
```

### Check Operation Again

After running `terraform apply` again, if you do not set the authentication information, access will fail as follows

```bash
http :8000/anything
HTTP/1.1 401 Unauthorized
...
{
    "message": "Unauthorized"
}
```

If you add the username and password, access will succeed.

```bash
http :8000/anything --auth alice-test:demo
HTTP/1.1 200 OK
...

{
    "args": {},
    "data": "",
    "files": {},
    "form": {},
    "headers": {
        "Accept": "*/*",
        "Accept-Encoding": "gzip, deflate",
        "Authorization": "Basic YWxpY2UtdGVzdDpkZW1v",
        "Host": "httpbin.org",
        "User-Agent": "HTTPie/2.6.0",
        "X-Amzn-Trace-Id": "Root=1-6704e137-4b63183d4b63d8bf460a923a",
        "X-Consumer-Custom-Id": "alice",
        "X-Consumer-Id": "5a32c0e9-035a-404c-95d1-1df3313a768d",
        "X-Consumer-Username": "alice",
        "X-Credential-Identifier": "alice-test",
        "X-Forwarded-Host": "localhost",
        "X-Forwarded-Path": "/anything",
        "X-Kong-Request-Id": "a541603da784b779c217c81ff65b9556"
    },
    "json": null,
    "method": "GET",
    "origin": "172.21.0.1, 18.178.66.113",
    "url": "http://localhost/anything"
}
```

## Deleting the Configuration

```bash
terraform destroy
...

Plan: 0 to add, 0 to change, 5 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

kong-gateway_basic_auth.my_basicauth: Destroying... [id=9f419547-0b9b-41c9-a595-f22c1539ff34]
kong-gateway_route.hello: Destroying... [id=152c5f85-cf3b-466a-8d0f-ead33de8f6ca]
kong-gateway_plugin_basic_auth.my_pluginbasicauth: Destroying... [id=741a6c67-5ef0-4c4e-94ec-f8597ce89992]
kong-gateway_basic_auth.my_basicauth: Destruction complete after 0s
kong-gateway_plugin_basic_auth.my_pluginbasicauth: Destruction complete after 0s
kong-gateway_consumer.alice: Destroying... [id=5a32c0e9-035a-404c-95d1-1df3313a768d]
kong-gateway_route.hello: Destruction complete after 0s
kong-gateway_service.httpbin: Destroying... [id=13137290-ba88-432c-a9ea-d10465ffaa8f]
kong-gateway_consumer.alice: Destruction complete after 0s
kong-gateway_service.httpbin: Destruction complete after 0s

Destroy complete! Resources: 5 destroyed.
```

## Impressions

- Unlike deck, applying the configuration does not affect existing settings
- Unlike deck, Service and Route can be managed separately
- At the time of writing, `kong-admin-token` cannot be set, so it cannot be used in environments with RBAC enabled
  - There is an issue: [https://github.com/Kong/terraform-provider-kong-gateway/issues/4](https://github.com/Kong/terraform-provider-kong-gateway/issues/4)

***(20250403 Update) The issue has been resolved, and it can now be used in RBAC environments!***

[https://github.com/Kong/terraform-provider-kong-gateway/pull/7](https://github.com/Kong/terraform-provider-kong-gateway/pull/7)

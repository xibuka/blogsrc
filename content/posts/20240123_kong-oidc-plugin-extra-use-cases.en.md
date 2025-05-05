---
title: "Other Use Cases for the Kong OpenID Connect Plugin"
date: 2024-01-23T22:55:37+09:00
draft: false
tags:
- Kong Gateway
- plugin
- OpenID
---

(Translated from [https://tech.aufomm.com/kong-oidc-plugin-extra-use-cases/](https://tech.aufomm.com/kong-oidc-plugin-extra-use-cases/))

The Kong OIDC plugin is very powerful and complex (it has nearly 200 parameters...), so if you know what combination of settings you need, you can do a lot more. In today's post, I'll introduce some use cases to help you make better use of this plugin.

Note: I'm using Kong Gateway (Enterprise) version 2.4.1.1.

> Prerequisites
>
> - Kong Gateway (Enterprise)
> - An OIDC server is running (Keycloak in my example). If you don't know how to use Keycloak, see my previous post.

## Extracting Data from IDP Tokens and Adding to Headers

If you want to map values from an IDP token to upstream headers, you can use `config.upstream_headers_names` and `config.upstream_headers_claims`.

For example, suppose the JWT token payload has the following claim:

```json
{
  "payload": {
    "kong-test": "to-upstream"
  }
}
```

The goal is to map the value `to-upstream` to the header `kong-test` and send it to the upstream server. The OIDC plugin can be configured as follows (using the password flow):

```bash
curl --request POST \
  --url http://kong.li.lan:8001/plugins \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data name=openid-connect \
  --data config.issuer=https://<keycloak>/auth/realms/demo \
  --data config.client_id=<client_id> \
  --data config.client_secret=<client_secret> \
  --data config.auth_methods=password \
  --data config.upstream_headers_claims=kong-test \
  --data config.upstream_headers_names=test_kong 
```

When you call the API endpoint with a username and password, you should see the following header in the request sent to the upstream server:

```json
"Test-Kong": "to-upstream",
```

If the value is an object (e.g., you want to pass employee info upstream as a header), it will be base64 encoded.

```json
{
  "payload": {
    "employee": {
      "favourites": {
        "beverage": "coffee"
      },
      "groups": [
        "default",
        "it"
      ],
      "name": "li"
    }
  }
}
```

Let's enable the plugin:

```bash
curl --request POST \
  --url http://kong.li.lan:8001/plugins \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data name=openid-connect \
  --data config.issuer=https://<keycloak>/auth/realms/demo \
  --data config.client_id=<client_id> \
  --data config.client_secret=<client_secret> \
  --data config.auth_methods=password \
  --data config.upstream_headers_claims=employee \
  --data config.upstream_headers_names=x-employee-info
```

After authentication, the upstream should receive a header like this:

```bash
"X-Employee-Info": [
  "eyJuYW1lIjoibGkiLCJmYXZvdXJpdGVzIjp7ImJldmVyYWdlIjoiY29mZmVlIn0sImdyb3VwcyI6WyJkZWZhdWx0IiwiaXQiXX0="
]
```

## Checking Received Tokens

Sometimes, you may have trouble setting up the OIDC plugin, and the logs don't show the info you need. For example, you might see `kong failed to find the consumer for consumer mapping` in the logs, but the token should have this info (this can happen if you forget to include a scope in the request, so the claim isn't added).

The best way to debug in this situation is to check the token returned from the IDP. To do this, set `config.login_action=response` and `config.login_tokens=tokens`.

For example:

1. Enable the OIDC plugin with the `authorization_code flow`:

    ```bash
    curl --request POST \
    --url http://kong.li.lan:8001/plugins \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --data name=openid-connect \
    --data config.issuer=https://<keycloak>/auth/realms/demo \
    --data config.client_id=<client_id> \
    --data config.client_secret=<client_secret> \
    --data config.auth_methods=authorization_code \
    --data config.login_action=response \
    --data config.login_tokens=tokens
    ```

2. Use a browser to access `https://<kong_proxy>/<oidc_protected_route>`.
3. After logging in, you'll see the token from the IDP.

## Multiple Required Claims

If your application requires specific claims with certain values in the JWT token from the IDP, you can use the following four pairs to validate the JWT token:

- `config.groups_claim` and `config.groups_required`
- `config.scopes_claim` and `config.scopes_required`
- `config.roles_claim` and `config.roles_required`
- `config.audience_claim` and `config.audience_required`

The parameter names don't matter; you can set them to any claim. There are some guidelines for using them:

- You can validate up to four claims at the same time.
- You can validate multiple values for the same claim using OR and AND logic.
- You can traverse arrays/objects in claim names.

For example, suppose you get the following `employee` claim in a JWT token:

```json
"employee": {
  "name": "li",
  "groups": [
    "default",
    "it"
  ],
  "favourites": {
    "beverage": "coffee"
  }
}
```

### Checking All Values in a Claim Array

If you only want to allow employees whose favorite beverage is coffee, you can enable the OIDC plugin as follows:

```bash
curl --request POST \
  --url http://kong.li.lan:8001/plugins \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data name=openid-connect \
  --data config.issuer=https://<keycloak>/auth/realms/demo \
  --data config.client_id=<client_id> \
  --data config.client_secret=<client_secret> \
  --data config.auth_methods=password \
  --data config.scopes_required=coffee \
  --data config.scopes_claim=employee \
  --data config.scopes_claim=favourites \
  --data config.scopes_claim=beverage
```

As you can see, `"scopes_claim":["employee", "favorites", "beverage"]` is set as an array, and `config.scopes_required=coffee`. Kong will check all JWT claims and verify if `beverage` equals `coffee`. If the returned JWT does not have `beverage=coffee`, the user will receive `HTTP/1.1 403 Forbidden`.

### Validating Multiple Values for a Specific Claim

- AND
To allow access only to users who belong to both the `default` and `it` groups, enable the OIDC plugin as follows:

```bash
curl --request POST \
  --url http://kong.li.lan:8001/plugins \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data name=openid-connect \
  --data config.issuer=https://<keycloak>/auth/realms/demo \
  --data config.client_id=<client_id> \
  --data config.client_secret=<client_secret> \
  --data config.auth_methods=password \
  --data 'config.scopes_required=default it' \
  --data config.scopes_claim=employee \
  --data config.scopes_claim=groups
```

- OR
To allow access to users who belong to either the `default` or `it` group, enable the OIDC plugin as follows:

```bash
curl --request POST \
--url http://kong.li.lan:8001/plugins \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data name=openid-connect \
--data config.issuer=https://<keycloak>/auth/realms/demo \
--data config.client_id=<client_id> \
--data config.client_secret=<client_secret> \
--data config.auth_methods=password \
--data 'config.scopes_required=default' \
--data 'config.scopes_required=it' \
--data config.scopes_claim=employee \
--data config.scopes_claim=groups
```

The key is `config.scopes_required`. Different array indices mean OR, and values separated by spaces in the same array index mean AND.

## Passing Additional Arguments to the Authorization Endpoint

When using the authorization code flow, unrelated query arguments in the redirect URL are removed. You can add additional query arguments to the authorization endpoint's query string with the following settings.

### Adding Variable Values

Suppose you want to pass a query argument to the IDP to specify who is accessing the server. For example, by setting `config.authorization_query_args_client`, you can pass the username or email to the IDP.

```bash
curl --request POST \
  --url http://kong.li.lan:8001/plugins \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data name=openid-connect \
  --data config.issuer=https://<keycloak>/auth/realms/demo \
  --data config.client_id=<client_id> \
  --data config.client_secret=<client_secret> \
  --data config.auth_methods=authorization_code \
  --data config.authorization_query_args_client=username 
```

Then, when you access `https://<kong_proxy>/<protected_route>?username=admin`, you should see that `username=admin` is added.

### Adding Fixed Values

If you want to add fixed values, you can use `config.authorization_query_args_names` and `config.authorization_query_args_values` to add multiple name-value pairs.

```bash
curl --request POST \
  --url http://kong.li.lan:8001/plugins \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data name=openid-connect \
  --data config.issuer=https://<keycloak>/auth/realms/demo \
  --data config.client_id=<client_id> \
  --data config.client_secret=<client_secret> \
  --data config.auth_methods=authorization_code \
  --data config.authorization_query_args_names=user \
  --data config.authorization_query_args_values=demo
```

Now, when you access `https://<kong_proxy>/<protected_route>`, you should see `user=demo` in the authentication URL.

That's all for today. Next time, I'll introduce how to use client authentication with OIDC.

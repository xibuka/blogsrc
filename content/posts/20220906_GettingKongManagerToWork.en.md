---
title: "Configuration for Deploying Kong Manager with Hostname"
date: 2022-09-07T00:40:42+09:00
draft: false
tags: 
- Kong Gateway
---

> **_NOTE:_** Translated from `https://svenwal.de/blog/20210316_kong_manager_install/`

TL;DR: If Kong Manager is not working, check the settings for `KONG_ADMIN_API_URI` and `KONG_ADMIN_GUI_URL`.

## Introduction to Kong Manager

Since February 2021, Kong Manager (previously an Enterprise feature for many years) has become part of the free version of Kong.

I have used Kong Manager for a long time and have helped many users set it up correctly, so I would like to share some typical configuration issues.

## Kong Manager is Easy to Use

Kong Manager works out of the box. If you install and enable Kong (Free or Enterprise) on your local machine, you can immediately access Kong Manager at <http://localhost:8002>.

![image](https://svenwal.de/img/Kong_Manager_localhost.jpeg)
![image](https://svenwal.de/img/Kong_Manager_diagram_localhost.jpeg)

## How It Breaks (and How to Fix It)

In real installations, instead of placing Kong Manager on a local machine, you install it on a server and access it using proper DNS entries. While doing so, you want to use a different hostname instead of a port like 8002.

![image](https://svenwal.de/img/Kong_Manager_behind_loadbalancer.jpeg)

Suppose Kong is installed behind a LoadBalancer/Ingress/... and Kong Manager is exposed with a nice hostname like `https://kong-manager.my-company.example.com`. When you open this, Kong Manager appears, but the default workspace is missing, and there is no button to create a new workspace. So, what happened?

![image](https://svenwal.de/img/Kong_Manager_broken.jpeg)

Everything in Kong is API-based, and the entire Kong Manager UI is a browser-based application running locally in your browser. If you haven't changed the settings, it will start making calls to the default Admin-API address (`http://localhost:8001`).

Since Kong cannot know the external URL of the Admin-API, you need to specify it in the configuration. For example, if you map port 8001 to `https://kong-admin.my-company.example.com`, you need to set it as follows:

```YAML
admin_api_uri = https://kong-admin.my-company.example.com
```

Or (if using environment variables):

```YAML
kong_admin_api_uri = https://kong-admin.my-company.example.com
```

Now, the browser knows where the Admin API is and starts making calls. However, when you actually try it, you still can't access it properly. So, what's missing?

We created different hostnames for Kong Manager and the Admin API, which triggers the browser's CORS protection. JavaScript on `https://kong-manager.my-company.example.com` tries to call `https://kong-admin.my-company.example.com`, and the browser rejects it (due to cross-origin). So, as a second step, you need to check if the Admin-API is sending the correct `Allow-Origin-Header`. For that, you need to tell Kong what the Kong Manager URL is.

```YAML
admin_gui_url = https://kong-manager.my-company.example.com
```

Or (if using environment variables):

```YAML
KONG_ADMIN_GUI_URL = https://kong-manager.my-company.example.com
```

![image](https://svenwal.de/img/Kong_Manager_behind_loadbalancer.jpeg)

Now you can successfully access the Workspace.

![image](https://svenwal.de/img/Kong_Manager_working.jpeg)

## Enabling RBAC and Logging

If you are using Kong Enterprise, you usually need to protect the Admin-API and Kong Manager with RBAC. Suppose you set up everything for basic-auth and the `Kong-Admin-Token` header works well with the admin API. However, when you open the browser and log in (hint: if you set a password at startup, the default username is kong_admin), it doesn't work as expected.

In the above example, the login itself works, but the created session cookie is not valid for both domains (`https://kong-manager.my-company.example.com` and the Admin-API). When you log in at `https://kong-manager.my-company.example.com`, the cookie is only valid for the UI, not for the Admin-API.

To make the browser accept this cookie for both DNS entries, you need to configure it to be valid for both.

```YAML
admin_gui_session_conf = {"cookie_domain": "my-company.example.com", "secret": "your-random-secret", "cookie_secure":false} 
```

Or (if using environment variables):

```YAML
KONG_ADMIN_GUI_SESSION_CONF = {"cookie_domain": "my-company.example.com", "secret": "your-random-secret", "cookie_secure": false}.
```

The important part here is `cookie_domain`. You need to set a subdomain that is shared by both URLs. In this example, `my-company.example.com` is shared by both.

Hint: In this example, I also added Cookie_secure. If you are exposing Kong only via http, you may want to add this.

> **_NOTE:_** For certain domains, especially those from cloud providers (e.g., `.amazonaws.com`), cookies are blocked in the browser. If you have cookie issues, refer to this [StackOverflow post](https://stackoverflow.com/questions/43520667/cookies-are-not-being-set-for-amazonaws-com-in-chrome-57-and-58-browsers).

## Developer Portal Too

Having learned a lot about the main principles of API-based user interfaces, the Developer Portal also shares the same principles (web-based UI and API). Therefore, you need to do similar things to make it work.

```YAML
portal_gui_protocol = https
portal_gui_host = kong-portal.my-company.example.com
portal_api_url = https://kong-portal-api.my-company.example.com
portal_session_conf = {"cookie_name":"portal_session","secret":"another-random-secret","cookie_secure":false,"cookie_domain":"my-company.example.com"} 
```

Or (if using environment variables):

```YAML
KONG_PORTAL_GUI_PROTOCOL = https
KONG_PORTAL_GUI_HOST = kong-portal.my-company.example.com
KONG_PORTAL_API_URL = https://kong-portal-api.my-company.example.com
KONG_PORTAL_SESSION_CONF = {"cookie_name":"portal_session","secret":"another-random-secret","cookie_secure":false,"cookie_domain":"my-company.example.com"} 
```

If you are using OpenID Connect, this setting is not required. Instead, check the OIDC plugin's config.session_cookie_domain (in this example, config.session_cookie_domain=my-company.example.com).

> **_NOTE:_** For certain domains, especially those from cloud providers (e.g., `.amazonaws.com`), cookies are blocked in the browser. If you have cookie issues, refer to this [StackOverflow post](https://stackoverflow.com/questions/43520667/cookies-are-not-being-set-for-amazonaws-com-in-chrome-57-and-58-browsers).

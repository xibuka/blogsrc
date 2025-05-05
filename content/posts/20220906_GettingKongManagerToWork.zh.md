---
title: "Kong Manager 主机名部署配置"
date: 2022-09-07T00:40:42+09:00
draft: false
tags: 
- Kong Gateway
---

> **_NOTE:_** 翻译自 `https://svenwal.de/blog/20210316_kong_manager_install/`

TL;DR：如果 Kong Manager 无法正常工作，请检查 `KONG_ADMIN_API_URI` 和 `KONG_ADMIN_GUI_URL` 的设置。

## Kong Manager 简介

自 2021 年 2 月起，Kong Manager（长期以来是 Kong Enterprise 的功能）已成为 Kong 免费版的一部分。

我长期使用 Kong Manager，也帮助过许多用户正确配置它，这里想分享一些典型的配置问题。

## Kong Manager 易于使用

Kong Manager 开箱即用。在本地机器上安装并启用 Kong（免费或企业版）后，可以直接通过 <http://localhost:8002> 访问 Kong Manager。

![image](https://svenwal.de/img/Kong_Manager_localhost.jpeg)
![image](https://svenwal.de/img/Kong_Manager_diagram_localhost.jpeg)

## 常见问题与修复

实际部署时，通常不是在本地机器上运行 Kong Manager，而是安装在服务器上，并通过合适的 DNS 入口访问。同时，你希望用不同的主机名而不是像 8002 这样的端口。

![image](https://svenwal.de/img/Kong_Manager_behind_loadbalancer.jpeg)

假设 Kong 安装在 LoadBalancer/Ingress/... 后面，Kong Manager 通过 `https://kong-manager.my-company.example.com` 这样的主机名暴露。当你访问时，Kong Manager 页面能打开，但默认工作区消失了，也没有新建工作区的按钮。发生了什么？

![image](https://svenwal.de/img/Kong_Manager_broken.jpeg)

Kong 的一切都是基于 API 的，Kong Manager 的整个 UI 其实是运行在本地浏览器中的 Web 应用。如果你没有修改配置，它会默认调用 Admin-API 地址（`http://localhost:8001`）。

由于 Kong 无法自动得知 Admin-API 的外部 URL，需要在配置中指定。例如，如果你将 8001 端口映射到 `https://kong-admin.my-company.example.com`，则需要这样设置：

```YAML
admin_api_uri = https://kong-admin.my-company.example.com
```

或者（使用环境变量时）：

```YAML
kong_admin_api_uri = https://kong-admin.my-company.example.com
```

此时浏览器就知道 Admin API 的地址并开始请求。但实际测试时，依然无法正常访问。还缺了什么？

我们为 Kong Manager 和 Admin API 配置了不同的主机名，这会触发浏览器的 CORS 保护。`https://kong-manager.my-company.example.com` 上的 JavaScript 会尝试请求 `https://kong-admin.my-company.example.com`，浏览器会因跨域而拒绝。所以第二步，需要确认 Admin-API 是否返回了正确的 `Allow-Origin-Header`。为此，需要告诉 Kong Manager 的 URL。

```YAML
admin_gui_url = https://kong-manager.my-company.example.com
```

或者（使用环境变量时）：

```YAML
KONG_ADMIN_GUI_URL = https://kong-manager.my-company.example.com
```

![image](https://svenwal.de/img/Kong_Manager_behind_loadbalancer.jpeg)

这样就能正常访问 Workspace 了。

![image](https://svenwal.de/img/Kong_Manager_working.jpeg)

## 启用 RBAC 和日志

如果你使用 Kong Enterprise，通常需要用 RBAC 保护 Admin-API 和 Kong Manager。假设你已为 basic-auth 和 `Kong-Admin-Token` header 配置好 Admin API，但在浏览器登录时（提示：如果启动时设置了密码，默认用户名是 kong_admin），却无法正常使用。

上面例子中，登录本身没问题，但创建的 session cookie 并不同时对两个域名有效（`https://kong-manager.my-company.example.com` 和 Admin-API）。在 `https://kong-manager.my-company.example.com` 登录后，cookie 只对 UI 有效，对 Admin-API 无效。

要让浏览器在两个 DNS 入口都接受 cookie，需要配置 cookie 对两个域名都有效。

```YAML
admin_gui_session_conf = {"cookie_domain": "my-company.example.com", "secret": "your-random-secret", "cookie_secure":false} 
```

或者（使用环境变量时）：

```YAML
KONG_ADMIN_GUI_SESSION_CONF = {"cookie_domain": "my-company.example.com", "secret": "your-random-secret", "cookie_secure": false}.
```

这里最重要的是 `cookie_domain`，需要设置为两个 URL 共同的子域名。本例中就是 `my-company.example.com`。

提示：本例还加了 Cookie_secure。如果你只用 http 暴露 Kong，可以加上这个参数。

> **_NOTE:_** 某些特殊域名，尤其是云服务商的域名（如 `.amazonaws.com`），浏览器会阻止 cookie。如果遇到 cookie 问题，请参考 [StackOverflow 这篇帖子](https://stackoverflow.com/questions/43520667/cookies-are-not-being-set-for-amazonaws-com-in-chrome-57-and-58-browsers)。

## Developer Portal 也一样

了解了 API 驱动 UI 的主要原理后，Developer Portal 也是同样的机制（Web UI + API）。因此，也需要类似的配置。

```YAML
portal_gui_protocol = https
portal_gui_host = kong-portal.my-company.example.com
portal_api_url = https://kong-portal-api.my-company.example.com
portal_session_conf = {"cookie_name":"portal_session","secret":"another-random-secret","cookie_secure":false,"cookie_domain":"my-company.example.com"} 
```

或者（使用环境变量时）：

```YAML
KONG_PORTAL_GUI_PROTOCOL = https
KONG_PORTAL_GUI_HOST = kong-portal.my-company.example.com
KONG_PORTAL_API_URL = https://kong-portal-api.my-company.example.com
KONG_PORTAL_SESSION_CONF = {"cookie_name":"portal_session","secret":"another-random-secret","cookie_secure":false,"cookie_domain":"my-company.example.com"} 
```

如果你用 OpenID Connect，则无需上述设置，直接检查 OIDC 插件的 config.session_cookie_domain（本例为 config.session_cookie_domain=my-company.example.com）。

> **_NOTE:_** 某些特殊域名，尤其是云服务商的域名（如 `.amazonaws.com`），浏览器会阻止 cookie。如果遇到 cookie 问题，请参考 [StackOverflow 这篇帖子](https://stackoverflow.com/questions/43520667/cookies-are-not-being-set-for-amazonaws-com-in-chrome-57-and-58-browsers)。

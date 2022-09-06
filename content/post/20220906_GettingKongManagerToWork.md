---
title: "Kong Managerをホストネームでデプロイための設定"
date: 2022-09-07T00:40:42+09:00
draft: false
---

> **_NOTE:_** https://svenwal.de/blog/20210316_kong_manager_install/ より翻訳

TL;DR: Kong Managerが動作しない場合は、`KONG_ADMIN_API_URI`と`KONG_ADMIN_GUI_URL`の設定を確認してください。

## The Kong Manager

2021年2月より、Kong Manager（長年Kong Enterpriseの機能でした）はKongの無料版の一部となりました。

私は長い間Kong Managerを使用しており、多くのユーザーが正しくセットアップするのを助けてきましたので、幾つの典型的な設定の問題を共有したいと思います。

## Works out of the box

Kong Managerはout of the boxでありすぐに使えます。ローカル マシンに Kong (Free または Enterprise) をインストールし、有効にすると、 <http://localhost:8002>でKong Managerをすぐアクセスできます。

![image](https://svenwal.de/img/Kong_Manager_localhost.jpeg)
![image](https://svenwal.de/img/Kong_Manager_diagram_localhost.jpeg)

## 壊れ方 (直し方)

実際のインストールでは、Kong Managerを適当なローカルマシンに置くのではなく、サーバーにインストールし、適切なDNSエントリを使ってアクセスする必要があります。そして、そうしている間、8002のようなポートを持つのではなく、異なるホストネームを使用したいのです。

![image](https://svenwal.de/img/Kong_Manager_behind_loadbalancer.jpeg)

それでは、KongはLoadBalancer/Ingress/...の後ろにインストールされ、Kong Managerを`https://kong-manager.my-company.example.com`のような素敵なホスト名でを公開していると仮定しましょう。これを開くと、Kongマネージャが表示されますが、デフォルトのワークスペースは消えていて、新しいワークスペースを作成するボタンもありません。では、何が起こったのでしょうか？

![image](https://svenwal.de/img/Kong_Manager_broken.jpeg)

KongのすべてがAPIであり、Kong Managerのユーザーインターフェイス全体が、ローカルのブラウザで動作するブラウザベースのアプリケーションであリます。そして、設定を変更していない場合、デフォルトのAdmin-APIアドレス（http://localhost:8001）への呼び出しが開始されます。

KongはAdmin-APIの外部URLを知ることができないため、設定でそれを指定する必要があります。例えば、8001-Portを`https://kong-admin.my-company.example.com` のようにマッピングしたとすると、次のように設定する必要があります。

```YAML
admin_api_uri = https://kong-admin.my-company.example.com
```

または（環境変数を使用している場合）

```YAML
kong_admin_api_uri = https://kong-admin.my-company.example.com
```

これで、ブラウザはAdmin APIがどこにあるかを知り、呼び出しを開始するようになりました。しかし、実際に試してみると、やはりうまくアクセスできません。では、何が足りないのでしょうか？

私たちはKong ManagerとAdmin APIに異なるホスト名を作成しましたが、これはブラウザのCORS保護をトリガーします。`https://kong-manager.my-company.example.com` 上の JavaScript は `https://kong-admin.my-company.example.com` への呼び出しを試み、ブラウザはそれを拒否します（クロスオリジンのため）。そこで、第二段階として、Admin-API が正しい `Allow-Origin-Header` を送信しているかどうかを確認する必要があります。そのためには、Kong ManagerのURLがどのようなものであるかをKongに伝える必要があります。

```YAML
admin_gui_url = https://kong-manager.my-company.example.com
```

または（環境変数を使用している場合）

```YAML
KONG_ADMIN_GUI_URL = https://kong-manager.my-company.example.com
```

![image](https://svenwal.de/img/Kong_Manager_behind_loadbalancer.jpeg)

これで無事Workspaceにアクセスすることができました。

![image](https://svenwal.de/img/Kong_Manager_working.jpeg)

## Enabling RBAC and logging in not possible

Kong Enterpriseを使用する場合、通常、RBACを使用してAdmin-APIとKong Managerを保護する必要があります。Basic-authに対しすべてをセットアップし、`Kong-Admin-Token` headerがadmin APIでうまく機能すると仮定してみましょう。しかし、ブラウザを開いてログインすると（ヒント：起動時にパスワードを設定した場合、標準のユーザ名はkong_adminです）、うまくいきません。

上記の例では、ログイン自体はうまくいきますが、作成されたセッションcookieが両方のドメインで有効ではありません（`https://kong-manager.my-company.example.com` でログインすると、cookieは UI でのみ有効で、Admin-API では有効ではありません）。

このcookieをブラウザがDNS名で受け入れるようにするためには、両方のDNSエントリで有効になるように設定する必要があります。

```YAML
admin_gui_session_conf = {"cookie_domain": "my-company.example.com", "secret": "your-random-secret", "cookie_secure":false} 
```

または (環境変数を使っている場合)

```YAML
KONG_ADMIN_GUI_SESSION_CONF = {"cookie_domain": "my-company.example.com", "secret": "your-random-secret", "cookie_secure": false}.
```

ここで重要なのは `cookie_domain` です。両方の URL が共通に持つサブドメインを設定する必要があります。この例では `my-company.example.com` が両方の URL で共有されています。

ヒント: この例では、Cookie_secureも追加しています。httpのみでKongを公開している場合に備えて、ここに追加しておきたいと思っただけです。

> **_NOTE:_** 特定のドメイン、特にクラウドプロバイダーからのドメイン（例えば`.amazonaws.com`）は、ブラウザ内でcookieがブロックされています。cookieに問題がある場合は、[StackOverflow](https://stackoverflow.com/questions/43520667/cookies-are-not-being-set-for-amazonaws-com-in-chrome-57-and-58-browsers)のこの投稿を参照してください。

## Developer Portal

API ベースのユーザーインターフェースの主要な原則について多くを学んだので、Developer Portal(開発者ポータル)についても同じ原則（ウェブベースのユーザーインターフェースと API）を共有しています。そのため、これを動作させるために同様のことをしなければならないです。

```YAML
portal_gui_protocol = https
portal_gui_host = kong-portal.my-company.example.com
portal_api_url = https://kong-portal-api.my-company.example.com
portal_session_conf = {"cookie_name":"portal_session","secret":"another-random-secret","cookie_secure":false,"cookie_domain":"my-company.example.com"} 
```

または (環境変数を使っている場合)

```YAML
KONG_PORTAL_GUI_PROTOCOL = https
KONG_PORTAL_GUI_HOST = kong-portal.my-company.example.com
KONG_PORTAL_API_URL = https://kong-portal-api.my-company.example.com
KONG_PORTAL_SESSION_CONF = {"cookie_name":"portal_session","secret":"another-random-secret","cookie_secure":false,"cookie_domain":"my-company.example.com"} 
```

OpenID Connectを使用する場合、この設定は必要ありません。代わりに、OIDCプラグインのconfig.session_cookie_domainを確認してください（この例では、config.session_cookie_domain=my-company.example.comとなります）。

> **_NOTE:_** 特定のドメイン、特にクラウドプロバイダーからのドメイン（例えば`.amazonaws.com`）は、ブラウザ内でcookieがブロックされています。cookieに問題がある場合は、[StackOverflow](https://stackoverflow.com/questions/43520667/cookies-are-not-being-set-for-amazonaws-com-in-chrome-57-and-58-browsers)のこの投稿を参照してください。

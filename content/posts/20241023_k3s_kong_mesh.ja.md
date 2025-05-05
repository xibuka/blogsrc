---
title: "K3s + kong Mesh deployment"
date: 2024-10-23T23:49:19+09:00
draft: false
tags:
- KongMesh
- k3s
---

Kong Meshは、サービスメッシュの管理を簡素化するためのプラットフォームで、マイクロサービス間の通信を安全かつ効率的に管理します。セキュリティ、可観測性、トラフィック制御といった機能を提供し、サイドカーアーキテクチャを利用して、各サービス間の通信をプロキシします。KubernetesやVMに対応し、異なる環境間でも統一したネットワーク管理を実現します。これにより、開発者はアプリケーションに集中でき、運用の複雑さを軽減できます。

この記事は、Kong Meshのデプロイ方法と、ポリシーの使い方をメモします。

## K8s 環境の準備

標準のk8s環境であればどれでも大丈夫ですが、今回自分はk3sを使います。

```bash
export INSTALL_K3S_EXEC="--tls-san <ip address> --write-kubeconfig ~/.kube/config --write-kubeconfig-mode 644"
curl -sfL https://get.k3s.io | sh -
```

shの前に `INSTALL_K3S_CHANNEL=v1.24.4+k3s1`みたいのを入れればインストールするバージョンを指定できますが、省略する場合は最新のバージョンになります。

```zsh
kubectl get node
NAME          STATUS   ROLES                  AGE     VERSION
wenhan-demo   Ready    control-plane,master   5m56s   v1.30.4+k3s1
```

## Kong Meshのデプロイメント

今回はまずシンプルなSingle Zone構成をデプロイします。

### Kumactl

kumactlは、Kong MeshやKumaの管理用CLIツールで、サービスメッシュの設定やリソースの操作を簡単に行えます。CLIコマンドで、メッシュのデプロイ、ポリシー設定、監視が可能です。
以下の手順で`kumactl`を展開し、`PATH`にも追加します。
こちらも同じく、VERSIONを省略したら最新のバージョンがインストールされます。

```bash
curl -L https://docs.konghq.com/mesh/installer.sh | VERSION=2.8.2 sh -

cd kong-mesh-2.8.2/bin
export PATH=$(pwd):$PATH
```

### Kong Mesh Control Plane

以下のコマンドでKong Mesh Control Planeをk8s上にデプロイします。
ここで初めてkumactlを使います。インストールに必要なCRDなどが生成してくれます。
`--license-path`には、Kong Gatewayと同じライセンスファイルのパスをセットします。

```bash
kumactl install control-plane \
    --license-path=/home/ubuntu/license | kubectl apply -f -
```

デプロイが終わると、`kong-mesh-control-plane-xxxxx`のPodがRunning状態になり、`default`の`meshes`がデプロイされています。

```bash
kubectl get pods -n kong-mesh-system
NAME                                       READY   STATUS    RESTARTS   AGE
kong-mesh-control-plane-5d5cb5f55c-h59wb   1/1     Running   0          24s

kubectl get meshes
NAME      AGE
default   2m20s
```

Kong Mesh Control planeをアクセスするには、CLIとGUIの方法があります。
まずは`kong-mesh-control-plane`サービスを公開します。方法はなんでもありですが、今回はまずシンプルに`NodePort`でexposeします。

```bash
kubectl expose deployment kong-mesh-control-plane \
    -n kong-mesh-system \
    --type=NodePort \
    --name=kongmesh-cp \
    --port 5681

service/kongmesh-cp exposed

kubectl patch service kongmesh-cp \
    --namespace=kong-mesh-system  \
    --type='json' \
    --patch='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value":30001}]'

service/kongmesh-cp patched
```

#### serviceへのアクセス

上記で公開したサービスにアクセスすると、以下のような内容が出力されます。

  ```bash
    curl -sX GET http://<IP address>:30001 | jq
    {
      "hostname": "kong-mesh-control-plane-5d5cb5f55c-h59wb",
      "tagline": "Kong Mesh",
      "product": "Kong Mesh",
      "version": "2.8.2",
      "instanceId": "kong-mesh-control-plane-5d5cb5f55c-h59wb-2875",
      "clusterId": "ed1a75f5-caf5-4749-943b-0ad7c6c7a49d",
      "gui": "/gui",
      "basedOnKuma": "2.8.2"
    }
  ```

#### GUIでのアクセス

公開したサービスの後ろに、`/gui`を追加すると、GUI画面が表示されています。
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/bfe7f3f7-aac2-d5de-3821-762b8b3f8e3c.png)

#### kumactlからのアクセス

`kumactl`コマンドからでもKong Mesh Control Planeを確認することもできます。
まずは、kumactlコマンドに上記のControl Planeの情報を追加します。

```bash
kumactl config control-planes add \
    --name=kongmesh-cp \
    --address=http://18.178.66.113:30001 --overwrite
added Control Plane "kongmesh-cp"
switched active Control Plane to "kongmesh-cp"
```

`kumactl get meshes`から、現在のMeshの設定状況を確認できる。

```bash
kumactl get meshes
NAME      mTLS   METRICS   LOGGING   TRACING   LOCALITY   ZONEEGRESS   AGE
default   off    off       off       off       off        off          9h
```

### Kong MeshにAppを追加

リソースの`metadata.labels`に`kuma.io/sidecar-injection: enabled`を付与すれば、Kong Meshにそのリソースに含まれているものが追加されます。以下の例では、Namespaceにラベルを付与したので、このNamespace内の全てのPodにsidecar(DP)を追加し、Kong Meshで管理することになります。

#### Appのデプロイ

以下のdemo用のYAMLファイルを保存します。Front Endのサービスはページ表示、Redisのサービスはカウンターを保存する簡単なアプリです。

![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/1d89630d-f487-c1ba-a19d-e031c0a74da2.png)

```YAML
apiVersion: v1
kind: Namespace
metadata:
  name: kuma-demo
  labels:
    kuma.io/sidecar-injection: enabled
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: kuma-demo
spec:
  selector:
    matchLabels:
      app: redis
  replicas: 1
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
        - name: redis
          image: "redis"
          ports:
            - name: tcp
              containerPort: 6379
          lifecycle:
            postStart:
              exec:
                command: ["/usr/local/bin/redis-cli", "set", "zone", "local"]
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: kuma-demo
spec:
  selector:
    app: redis
  ports:
  - protocol: TCP
    port: 6379
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: kuma-demo
spec:
  selector:
    matchLabels:
      app: demo-app
  replicas: 1
  template:
    metadata:
      labels:
        app: demo-app
        version: v1
    spec:
      containers:
        - name: demo-app
          image: "thefosk/kuma-demo"
          env:
            - name: REDIS_HOST
              value: "redis.kuma-demo.svc.cluster.local"
            - name: REDIS_PORT
              value: "6379"
            - name: APP_VERSION
              value: "1.0"
            - name: APP_COLOR
              value: "#efefef"
          ports:
            - name: http
              containerPort: 5000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app-v2
  namespace: kuma-demo
spec:
  selector:
    matchLabels:
      app: demo-app
  replicas: 1
  template:
    metadata:
      labels:
        app: demo-app
        version: v2
    spec:
      containers:
        - name: demo-app
          image: "thefosk/kuma-demo"
          env:
            - name: REDIS_HOST
              value: "redis.kuma-demo.svc.cluster.local"
            - name: REDIS_PORT
              value: "6379"
            - name: APP_VERSION
              value: "2.0"
            - name: APP_COLOR
              value: "#5da36f"
          ports:
            - name: http
              containerPort: 5000
---
apiVersion: v1
kind: Service
metadata:
  name: demo-app
  namespace: kuma-demo
  annotations:
    5000.service.kuma.io/protocol: http
    ingress.kubernetes.io/service-upstream: "true"
spec:
  selector:
    app: demo-app
  ports:
  - protocol: TCP
    port: 5000
```

保存したYAMLファイルを使ってデモ用リソースを追加します。

```bash
kubectl apply -f counterapp.yaml
namespace/kuma-demo created
deployment.apps/redis created
service/redis created
deployment.apps/demo-app created
deployment.apps/demo-app-v2 created
service/demo-app created

kubectl get pod -n kuma-demo
NAME                          READY   STATUS    RESTARTS   AGE
demo-app-5db8dc7c7c-5lxv4     2/2     Running   0          31s
demo-app-v2-977f89977-szv4p   2/2     Running   0          31s
redis-b95455698-hk7sm         2/2     Running   0          31s
```

各Podにcontainerが二つあることから、Sidecarが追加されたことはわかります。

GUIの`Data Plane Proxies`を開いたら確認できます。

![iShot_2024-09-02_10.00.19.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/a5d6adf4-c8f0-4560-89ff-450461053d99.png)

kumactlコマンドからでも、現在管理中のSidecar(dataplane)を確認することができます。

```bash
kumactl inspect dataplanes
MESH      NAME                                    TAGS                                                                                                                                                                                                                                                                             STATUS   LAST CONNECTED AGO   LAST UPDATED AGO   TOTAL UPDATES   TOTAL ERRORS   CERT REGENERATED AGO   CERT EXPIRATION   CERT REGENERATIONS   CERT BACKEND   SUPPORTED CERT BACKENDS   KUMA-DP VERSION   ENVOY VERSION   DEPENDENCIES VERSIONS   NOTES
default   demo-app-5db8dc7c7c-5lxv4.kuma-demo     app=demo-app k8s.kuma.io/namespace=kuma-demo k8s.kuma.io/service-name=demo-app k8s.kuma.io/service-port=5000 kubernetes.io/hostname=wenhan-demo kuma.io/protocol=http kuma.io/service=demo-app_kuma-demo_svc_5000 kuma.io/zone=default pod-template-hash=5db8dc7c7c version=v1   Online   1m                   51s                9               0              never                  -                 0                    -                                        2.8.2             1.30.4          -
default   demo-app-v2-977f89977-szv4p.kuma-demo   app=demo-app k8s.kuma.io/namespace=kuma-demo k8s.kuma.io/service-name=demo-app k8s.kuma.io/service-port=5000 kubernetes.io/hostname=wenhan-demo kuma.io/protocol=http kuma.io/service=demo-app_kuma-demo_svc_5000 kuma.io/zone=default pod-template-hash=977f89977 version=v2    Online   1m                   51s                9               0              never                  -                 0                    -                                        2.8.2             1.30.4          -
default   redis-b95455698-hk7sm.kuma-demo         app=redis k8s.kuma.io/namespace=kuma-demo k8s.kuma.io/service-name=redis k8s.kuma.io/service-port=6379 kubernetes.io/hostname=wenhan-demo kuma.io/protocol=tcp kuma.io/service=redis_kuma-demo_svc_6379 kuma.io/zone=default pod-template-hash=b95455698                         Online   1m                   50s                9               0              never                  -                 0                    -                                        2.8.2             1.30.4          -

```

### Appの公開

このアプリにアクセスしてみましょう。やり方は複数ありますが、ここではGateway + Ingressの方法で公開します。

#### Install gateway

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

customresourcedefinition.apiextensions.k8s.io/gatewayclasses.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/gateways.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/httproutes.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/referencegrants.gateway.networking.k8s.io created

echo "
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
 name: kong
 annotations:
   konghq.com/gatewayclass-unmanaged: 'true'

spec:
 controllerName: konghq.com/kic-gateway-controller
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
 name: kong
spec:
 gatewayClassName: kong
 listeners:
 - name: proxy
   port: 80
   protocol: HTTP
" | kubectl apply -f -
gatewayclass.gateway.networking.k8s.io/kong created
gateway.gateway.networking.k8s.io/kong created

```

### Install Kong KIC and Ingress

```bash
kubectl create ns kong
kubectl label ns kong kuma.io/sidecar-injection='enabled'
helm install kong kong/ingress -n kong
WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: /home/ubuntu/.kube/config
WARNING: Kubernetes configuration file is world-readable. This is insecure. Location: /home/ubuntu/.kube/config
NAME: kong
LAST DEPLOYED: Mon Sep  2 10:02:13 2024
NAMESPACE: kong
STATUS: deployed
REVISION: 1
TEST SUITE: None

cat <<EOF | kubectl apply -f - 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: counterapp
  namespace: kuma-demo
  annotations:
    kubernetes.io/ingress.class: kong
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: demo-app
            port:
              number: 5000
EOF
```

これでKong-gateway-proxyを使って、デプロイしたAPPにアクセスすることができます。

```bash
kubectl get svc -n kong
NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                         AGE
kong-controller-validation-webhook   ClusterIP      10.43.225.243   <none>        443/TCP                         3m10s
kong-gateway-admin                   ClusterIP      None            <none>        8444/TCP                        3m10s
kong-gateway-manager                 NodePort       10.43.69.48     <none>        8002:32047/TCP,8445:31615/TCP   3m10s
kong-gateway-proxy                   LoadBalancer   10.43.97.252    <pending>     80:32333/TCP,443:31081/TCP      3m10s
```

`32333` portにアクセスすれば、デモAPPにアクセスすることができます。
適当にIncrementをクリックしたら、全てが正常に動作しているはずです。

![iShot_2024-09-02_10.49.44.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/5ec3f295-5407-74e9-6071-9d77eb8d3097.png)

## Kong Meshのポリシーを活用

ここからはKong Meshの本領を発揮するところです。Kong Meshのポリシーは、サービスメッシュ環境でセキュリティやアクセス管理、トラフィック制御を実現するためのルール設定をサポートするものです。これらのポリシーには、主に以下の要素が含まれます。

1. セキュリティポリシー: 通信の暗号化（mTLS）や認証・認可を通じて、マイクロサービス間のセキュリティを強化します。トラフィックが安全に通信されることを保証します
2. トラフィックポリシー: サービス間の通信ルールを定義します。リトライやタイムアウト設定、トラフィックシェーピング、ロードバランシングなどを管理することが可能です
3. 認可ポリシー: RBAC（Role-Based Access Control）に基づき、どのサービスやユーザーがどのリソースにアクセスできるかを制御します
4. 監査ポリシー: システム全体のアクティビティを記録し、監査ログを生成します。これにより、異常やセキュリティインシデントの早期検知が可能です

Kong Meshのポリシーは、これらの機能を通じて、分散システム全体のセキュリティ、パフォーマンス、信頼性を向上させることを目的としています。
[https://docs.konghq.com/mesh/latest/policies/introduction/](https://docs.konghq.com/mesh/latest/policies/introduction/)

ここでは、以下の二つのポリシーを適用して、Zero Trust networkを構築する方法を説明します。
[https://docs.konghq.com/mesh/latest/policies/meshpassthrough/](https://docs.konghq.com/mesh/latest/policies/meshpassthrough/)
[https://docs.konghq.com/mesh/latest/policies/meshtrafficpermission/](https://docs.konghq.com/mesh/latest/policies/meshtrafficpermission/)

### Zero-trust Networkの構築

#### mTLSの有効化

デフォルトでは、mTLSが無効になっています。

```bash
kumactl get meshes
NAME      mTLS   METRICS   LOGGING   TRACING   LOCALITY   ZONEEGRESS   AGE
default   off    off       off       off       off        off          9h
```

Kong Mesh内部にbuilt-inのCAがあるため、以下で簡単に有効することができます。

```bash
# config mesh to enable mtls
cat <<EOF | kubectl apply -f - 
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
    - name: ca-1
      type: builtin
EOF

kumactl get meshes
NAME      mTLS           METRICS   LOGGING   TRACING   LOCALITY   ZONEEGRESS   AGE
default   builtin/ca-1   off       off       off       off        off          9h
```

mTLSを有効化すれば、これで全てのトラフィックに、`meshtrafficpermission`が必要になっています。現在はまだ作っていないため、APPへのアクセスが失敗になるはずです。

Kong Meshのバージョンによって失敗にならないケースもありますが、それはデフォルトに`allow-all`の`meshtrafficpermission`が存在しているからです。

#### マイクロサービス間のアクセスを許可

例えば、以下のように`allow-all`のPermissionを作ったら、Mesh内の全てのトラフィックが正常のままになっています。

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-all
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  from:
  - targetRef:
      kind: Mesh
    default:
      action: Allow
EOF
```

もう少しコントロールしたいので、許可をマイクロベースレベルで設定してみます。
まずはFront EndのKong GatewayのサービスからAPPへの許可を設定します。

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: kong2frontend
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: MeshService
    name: demo-app_kuma-demo_svc_5000
  from:
  - targetRef:
      kind: MeshSubset
      tags:
        kuma.io/service: kong-gateway-admin_kong_svc_8444
    default:
      action: Allow
EOF
meshtrafficpermission.kuma.io/kong2frontend created
```

次に、APPからRedisへの許可を設定します。

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: frontend2backend
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: MeshService
    name: redis_kuma-demo_svc_6379
  from:
  - targetRef:
      kind: MeshSubset
      tags:
        kuma.io/service: demo-app_kuma-demo_svc_5000
    default:
      action: Allow
EOF
```

ここまでで、マイクロサービスレベルのアクセス許可を設定し、アプリケーションの動きが正常になるはずです。

## まとめ

Kong Meshは、サービスメッシュの管理を簡素化するプラットフォームで、マイクロサービス間の通信を安全かつ効率的に管理します。この記事では、Kong Meshのデプロイ方法とポリシーの使い方を説明しています。

1. **K8s環境の準備**: k3sを使用してKubernetes環境をセットアップします。

2. **Kong Meshのデプロイ**:
   - `kumactl`を使用してKong Mesh Control Planeをデプロイします。
   - `NodePort`を使用してControl Planeを公開し、CLIやGUIでアクセスします。

3. **アプリケーションのデプロイ**:
   - `kuma.io/sidecar-injection: enabled`ラベルを使用して、Namespace内のPodにサイドカーを追加します。
   - Redisとデモアプリをデプロイし、Kong Meshで管理します。

4. **アプリケーションの公開**:
   - GatewayとIngressを使用してアプリケーションを公開します。

5. **Kong Meshのポリシー活用**:
   - mTLSを有効化し、Zero Trust Networkを構築します。
   - `MeshTrafficPermission`を設定して、マイクロサービス間のアクセスを制御します。

このプロセスにより、Kong Meshを使用してセキュアで効率的なサービスメッシュを構築し、ポリシーを活用してトラフィックを管理する方法を学びます。

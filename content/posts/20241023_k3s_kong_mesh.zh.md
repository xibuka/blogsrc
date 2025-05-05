---
title: "K3s + Kong Mesh 部署实践"
date: 2024-10-23T23:49:19+09:00
draft: false
tags:
- KongMesh
- k3s
---

Kong Mesh 是一个简化服务网格管理的平台，可以安全高效地管理微服务间的通信。它提供安全性、可观测性、流量控制等功能，并通过 Sidecar 架构代理各服务间的通信。支持 Kubernetes 和虚拟机，能够在不同环境下实现统一的网络管理。这样开发者可以专注于应用本身，降低运维复杂度。

本文记录 Kong Mesh 的部署方法及其策略用法。

## K8s 环境准备

标准的 k8s 环境都可以，这里以 k3s 为例。

```bash
export INSTALL_K3S_EXEC="--tls-san <ip address> --write-kubeconfig ~/.kube/config --write-kubeconfig-mode 644"
curl -sfL https://get.k3s.io | sh -
```

如果在 sh 前加上 `INSTALL_K3S_CHANNEL=v1.24.4+k3s1`，可以指定安装版本。省略则安装最新版。

```zsh
kubectl get node
NAME          STATUS   ROLES                  AGE     VERSION
wenhan-demo   Ready    control-plane,master   5m56s   v1.30.4+k3s1
```

## Kong Mesh 部署

本次以最简单的 Single Zone 架构为例。

### Kumactl

kumactl 是 Kong Mesh/Kuma 的管理 CLI 工具，可用于服务网格的配置和资源操作。通过 CLI 命令可以部署网格、设置策略、监控资源。
按如下步骤安装 `kumactl` 并加入 `PATH`。省略 VERSION 则安装最新版。

```bash
curl -L https://docs.konghq.com/mesh/installer.sh | VERSION=2.8.2 sh -

cd kong-mesh-2.8.2/bin
export PATH=$(pwd):$PATH
```

### Kong Mesh 控制平面部署

用如下命令在 k8s 上部署 Kong Mesh 控制平面。首次使用 kumactl，会自动生成安装所需的 CRD。
`--license-path` 指定 Kong Gateway 相同的 license 文件路径。

```bash
kumactl install control-plane \
    --license-path=/home/ubuntu/license | kubectl apply -f -
```

部署完成后，`kong-mesh-control-plane-xxxxx` Pod 会处于 Running 状态，`default` mesh 也已部署。

```bash
kubectl get pods -n kong-mesh-system
NAME                                       READY   STATUS    RESTARTS   AGE
kong-mesh-control-plane-5d5cb5f55c-h59wb   1/1     Running   0          24s

kubectl get meshes
NAME      AGE
default   2m20s
```

Kong Mesh 控制平面可通过 CLI 或 GUI 访问。
首先用 NodePort 暴露 `kong-mesh-control-plane` 服务（方法不限，这里用 NodePort）。

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

#### 访问服务

访问暴露的服务会返回如下内容：

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

#### GUI 访问

在服务地址后加 `/gui` 可访问 GUI 页面。
![image.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/bfe7f3f7-aac2-d5de-3821-762b8b3f8e3c.png)

#### kumactl 访问

也可以用 kumactl 命令行查看控制平面。
先将控制平面信息添加到 kumactl。

```bash
kumactl config control-planes add \
    --name=kongmesh-cp \
    --address=http://18.178.66.113:30001 --overwrite
added Control Plane "kongmesh-cp"
switched active Control Plane to "kongmesh-cp"
```

用 `kumactl get meshes` 查看当前 mesh 配置。

```bash
kumactl get meshes
NAME      mTLS   METRICS   LOGGING   TRACING   LOCALITY   ZONEEGRESS   AGE
default   off    off       off       off       off        off          9h
```

### 向 Kong Mesh 添加应用

在资源的 `metadata.labels` 加上 `kuma.io/sidecar-injection: enabled`，即可将其纳入 Kong Mesh。下例为 Namespace 添加标签，Namespace 下所有 Pod 都会自动注入 Sidecar（DP），由 Kong Mesh 管理。

#### 应用部署

保存如下 demo 用 YAML 文件。Front End 服务负责页面展示，Redis 服务负责计数器存储，是个简单的演示应用。

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

用上面保存的 YAML 文件添加 demo 资源。

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

每个 Pod 有两个容器，说明 Sidecar 已注入。

也可以在 GUI 的 `Data Plane Proxies` 页面查看。

![iShot_2024-09-02_10.00.19.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/a5d6adf4-c8f0-4560-89ff-450461053d99.png)

用 kumactl 命令也能查看当前管理的 Sidecar（dataplane）。

```bash
kumactl inspect dataplanes
MESH      NAME                                    TAGS                                                                                                                                                                                                                                                                             STATUS   LAST CONNECTED AGO   LAST UPDATED AGO   TOTAL UPDATES   TOTAL ERRORS   CERT REGENERATED AGO   CERT EXPIRATION   CERT REGENERATIONS   CERT BACKEND   SUPPORTED CERT BACKENDS   KUMA-DP VERSION   ENVOY VERSION   DEPENDENCIES VERSIONS   NOTES
default   demo-app-5db8dc7c7c-5lxv4.kuma-demo     app=demo-app k8s.kuma.io/namespace=kuma-demo k8s.kuma.io/service-name=demo-app k8s.kuma.io/service-port=5000 kubernetes.io/hostname=wenhan-demo kuma.io/protocol=http kuma.io/service=demo-app_kuma-demo_svc_5000 kuma.io/zone=default pod-template-hash=5db8dc7c7c version=v1   Online   1m                   51s                9               0              never                  -                 0                    -                                        2.8.2             1.30.4          -
default   demo-app-v2-977f89977-szv4p.kuma-demo   app=demo-app k8s.kuma.io/namespace=kuma-demo k8s.kuma.io/service-name=demo-app k8s.kuma.io/service-port=5000 kubernetes.io/hostname=wenhan-demo kuma.io/protocol=http kuma.io/service=demo-app_kuma-demo_svc_5000 kuma.io/zone=default pod-template-hash=977f89977 version=v2    Online   1m                   51s                9               0              never                  -                 0                    -                                        2.8.2             1.30.4          -
default   redis-b95455698-hk7sm.kuma-demo         app=redis k8s.kuma.io/namespace=kuma-demo k8s.kuma.io/service-name=redis k8s.kuma.io/service-port=6379 kubernetes.io/hostname=wenhan-demo kuma.io/protocol=tcp kuma.io/service=redis_kuma-demo_svc_6379 kuma.io/zone=default pod-template-hash=b95455698                         Online   1m                   50s                9               0              never                  -                 0                    -                                        2.8.2             1.30.4          -

```

### 应用发布

下面尝试访问应用。方法有多种，这里用 Gateway + Ingress。

#### 安装 gateway

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

### 安装 Kong KIC 和 Ingress

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

这样就可以通过 Kong-gateway-proxy 访问已部署的 APP。

```bash
kubectl get svc -n kong
NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                         AGE
kong-controller-validation-webhook   ClusterIP      10.43.225.243   <none>        443/TCP                         3m10s
kong-gateway-admin                   ClusterIP      None            <none>        8444/TCP                        3m10s
kong-gateway-manager                 NodePort       10.43.69.48     <none>        8002:32047/TCP,8445:31615/TCP   3m10s
kong-gateway-proxy                   LoadBalancer   10.43.97.252    <pending>     80:32333/TCP,443:31081/TCP      3m10s
```

通过 `32333` 端口访问应用。
点击 Increment，所有功能应正常。

![iShot_2024-09-02_10.49.44.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/5ec3f295-5407-74e9-6071-9d77eb8d3097.png)

## Kong Mesh 策略应用

这部分是 Kong Mesh 的核心。Kong Mesh 策略支持在服务网格环境下设置安全、访问控制、流量管理等规则，主要包括：

1. **安全策略**：通过加密（mTLS）、认证和授权，提升微服务间安全性，确保流量安全传输。
2. **流量策略**：定义服务间通信规则，管理重试、超时、流量整形、负载均衡等。
3. **授权策略**：基于 RBAC（角色访问控制）控制服务/用户对资源的访问。
4. **审计策略**：记录系统全局活动并生成审计日志，便于异常或安全事件的早期发现。

Kong Mesh 策略通过这些功能提升分布式系统的安全性、性能和可靠性。
[https://docs.konghq.com/mesh/latest/policies/introduction/](https://docs.konghq.com/mesh/latest/policies/introduction/)

这里以如下两种策略为例，介绍如何构建 Zero Trust 网络：
[https://docs.konghq.com/mesh/latest/policies/meshpassthrough/](https://docs.konghq.com/mesh/latest/policies/meshpassthrough/)
[https://docs.konghq.com/mesh/latest/policies/meshtrafficpermission/](https://docs.konghq.com/mesh/latest/policies/meshtrafficpermission/)

### Zero-trust 网络构建

#### 启用 mTLS

默认 mTLS 是关闭的。

```bash
kumactl get meshes
NAME      mTLS   METRICS   LOGGING   TRACING   LOCALITY   ZONEEGRESS   AGE
default   off    off       off       off       off        off          9h
```

Kong Mesh 内置 CA，启用很简单：

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

启用 mTLS 后，所有流量都需要 `meshtrafficpermission`。由于还没创建，APP 访问会失败。

不同版本 Kong Mesh 可能不会失败，因为默认存在 `allow-all` 的 `meshtrafficpermission`。

#### 微服务间访问授权

比如创建 `allow-all` 权限，Mesh 内所有流量都能正常通信。

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

为了更细粒度控制，可以按微服务级别设置权限。
首先为 Front End Kong Gateway 服务到 APP 设置权限：

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

然后为 APP 到 Redis 设置权限：

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

至此，微服务级别的访问权限已设置，应用应可正常访问。

## 总结

Kong Mesh 是一个简化服务网格管理的平台，可以安全高效地管理微服务间通信。本文介绍了 Kong Mesh 的部署方法和策略用法。

1. **K8s 环境准备**：用 k3s 搭建 Kubernetes 环境。
2. **Kong Mesh 部署**：
   - 用 `kumactl` 部署 Kong Mesh 控制平面。
   - 用 NodePort 暴露控制平面，支持 CLI 和 GUI 访问。
3. **应用部署**：
   - 通过 `kuma.io/sidecar-injection: enabled` 标签为 Namespace 下 Pod 注入 Sidecar。
   - 部署 Redis 和 demo 应用，由 Kong Mesh 管理。
4. **应用发布**：
   - 通过 Gateway 和 Ingress 发布应用。
5. **Kong Mesh 策略应用**：
   - 启用 mTLS 构建 Zero Trust 网络。
   - 设置 `MeshTrafficPermission` 控制微服务间访问。

通过上述流程，你可以学会用 Kong Mesh 构建安全高效的服务网格，并通过策略灵活管理流量。

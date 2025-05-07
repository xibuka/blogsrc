---
title: Certified Kubernetes Administrator (CKA) 学习笔记
date: 2018-08-29 11:40:56
tags:
- Kubernetes
- CKA
---

## 安装

1. 安装 docker.io

```sh
apt install docker.io
```

如果你用其他 cgroup driver 安装了 docker，需要确保 docker 和 Kubernetes 使用相同的 cgroup driver。

```sh
cat << EOF >> /etc/docker/daemon.json
{
    "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
```

1. 向系统添加 apt key 和源

```sh
root@kube-master:~# curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
OK
root@kube-master:~# cat <<EOF >> /etc/apt/sources.list.d/kubernetes.list
> deb http://apt.kubernetes.io/ kubernetes-xenial main
> EOF
```

然后安装 kubernetes 相关包

```sh
root@kube-master:~# apt update -y
root@kube-master:~# apt install -y kubelet kubeadm kubectl
```

1. 使用 kubeadm 进行设置和配置

执行 `kubeadm init` 时必须选择 CNI，这里选择 flannel，所以要加 `--pod-network-cidr` 选项。

```sh
root@k8sm:~# kubeadm init --pod-network-cidr=10.244.0.0/16
```

等待一会儿后，你会看到如下提示，表示安装完成：

```sh
Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join 192.168.122.75:6443 --token .....<snip>
```

按照提示，以普通用户执行如下命令：

```sh
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

还要记下以 `kubeadm join` 开头的命令，后续让工作节点加入集群时会用到。

为了让 Pod 之间能互相通信，需要安装 Pod 网络插件。这里我们用 Flannel。

```sh
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

接下来运行如下命令，确保一切正常启动。

```sh
kubectl get pods --all-namespaces
```

如果看到 coredns-xxxxxx pod 处于 Running 状态，master 节点为 Ready，说明集群已准备好接受工作节点。

```sh
wshi@k8sm:~$ kubectl get pods --all-namespaces
NAMESPACE     NAME                           READY     STATUS    RESTARTS   AGE
kube-system   coredns-78fcdf6894-ltgw2       1/1       Running   0          17m
kube-system   coredns-78fcdf6894-n8hw2       1/1       Running   0          17m
kube-system   etcd-k8sm                      1/1       Running   0          16m
kube-system   kube-apiserver-k8sm            1/1       Running   0          16m
kube-system   kube-controller-manager-k8sm   1/1       Running   0          16m
kube-system   kube-flannel-ds-amd64-ktcqm    1/1       Running   0          1m
kube-system   kube-proxy-nczhf               1/1       Running   0          17m
kube-system   kube-scheduler-k8sm            1/1       Running   0          16m
wshi@k8sm:~$ kubectl get node
NAME      STATUS    ROLES     AGE       VERSION
k8sm      Ready     master    17m       v1.11.2
```

1. 设置其他节点并加入集群

剩下的工作节点同样安装 kubectl、kubeadm、kubelet、docker，然后执行前面记下的 `kubeadm join ...` 命令。
稍等片刻，所有工作节点都应为 Ready。

```sh
wshi@k8sm:~$ kubectl get node
NAME      STATUS    ROLES     AGE       VERSION
k8sm      Ready     master    44m       v1.11.2
k8sn1     Ready     <none>    11m       v1.11.2
k8sn2     Ready     <none>    11m       v1.11.2
```

## 运行 Job

Pod 内运行的应用称为"Job"。

大多数 Kubernetes 对象都是用 yaml 创建的。下面是一个用 perl 计算圆周率到 2000 位的小 Job 示例 yaml：

```YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: pi
spec:
  template:
    spec:
      containers:
      - name: pi
        image: perl
        command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
  backoffLimit: 4
```

在 master 节点上保存为 "pi-job.yaml"，用如下命令运行：

```bash
kubectl create -f pi-job.yaml
```

用如下命令查看 Job 详情：

```sh
$ kubectl get pod
...
pi-72c7r                                           0/1       Completed   0          3m

$ kubectl describe pod pi-72c7r
...
```

用如下命令查看日志（标准输出）：

```bash
$ kubectl logs pi-72c7r
3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938446095505822317253594081284811174502841027019385211055596446229489549303819644288109756659334461284756482337867831652712019091456485669234603486104543266482133936072602491412737245870066063155881748815209209628292540917153643678925903600113305305488204665213841469519415116094330572703657595919530921861173819326117931051185480744623799627495673518857527248912279381830119491298336733624406566430860213949463952247371907021798609437027705392171762931767523846748184676694051320005681271452635608277857713427577896091736371787214684409012249534301465495853710507922796892589235420199561121290219608640344181598136297747713099605187072113499999983729780499510597317328160963185950244594553469083026425223082533446850352619311881710100031378387528865875332083814206171776691473035982534904287554687311595628638823537875937519577818577805321712268066130019278766111959092164201989380952572010654858632788659361533818279682303019520353018529689957736225994138912497217752834791315155748572424541506959508295331168617278558890750983817546374649393192550604009277016711390098488240128583616035637076601047101819429555961989467678374494482553797747268471040475346462080466842590694912933136770289891521047521620569660240580381501935112533824300355876402474964732639141992726042699227967823547816360093417216412199245863150302861829745557067498385054945885869269956909272107975093029553211653449872027559602364806654991198818347977535663698074265425278625518184175746728909777727938000816470600161452491921732172147723501414419735685481613611573525521334757418494684385233239073941433345477624168625189835694855620992192221842725502542568876717904946016534668049886272327917860857843838279679766814541009538837863609506800642251252051173929848960841284886269456042419652850222106611863067442786220391949450471237137869609563643719172874677646575739624138908658326459958133904780275898
```

## 另一个 Job 示例

下面是一个使用 "busybox" 镜像并 sleep 10 秒的 Job 示例 yaml：

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: busybox
spec:
  template:
    spec:
      containers:
      - name: busybox
        image: busybox
        command: ["sleep", "10"]
      restartPolicy: Never
  backoffLimit: 4
```

## 部署 Pod

Pod 通常代表 Kubernetes 集群中运行的应用。以下是一个定义 Pod 的 yaml 示例：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: alpine
  namespace: default
spec:
  containers:
  - name: alpine
    image: alpine
    command:
      - sleep
      - "3600"
    imagePullPolicy: IfNotPresent
  restartPolicy: Always
```

### 运行 Pod

```bash
kubectl create -f alpine.yaml
```

### 删除 Pod

```bash
kubectl delete -f alpine.yaml
```

或者

```sh
kubectl delete pod alpine
```

```sh
kubectl delete pod/alpine
```

## 查看当前状态

```sh
kubectl get nodes
kubectl describe node node-name
kubectl get pods --all-namespaces -o wide
```

使用 `-n` 可以指定 namespace

```sh
kubectl get pods -n kube-system
```

## Deployment

nginx 部署的 yaml 文件示例：

```sh
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
```

### 创建 deployment 和 pod

```sh
kubectl create -f nginx-deployment.yaml
```

查看详细信息

```sh
kubectl describe deployment nginx-deployment
```

查看 pod 运行在哪个节点

```sh
$ kubectl get pod nginx-deployment-7fc9b7bd96-c6wwh -o wide
NAME                                READY     STATUS    RESTARTS   AGE       IP          NODE            NOMINATED NODE
nginx-deployment-7fc9b7bd96-c6wwh   1/1       Running   0          21h       10.1.33.6   juju-cfb27c-2   <none>
```

### 滚动升级镜像版本

将镜像版本改为 1.8，可以运行：

```sh
kubectl set image deployment nginx-deployment nginx=nginx:1.8
```

或者直接修改 yaml 文件中的镜像版本为 1.8，然后 apply

```sh
kubectl apply -f nginx-deployment.yaml
```

查看滚动升级状态

```sh
kubectl rollout status deployment nginx-deployment
```

回滚到上一个版本

```sh
kubectl rollout undo deployment nginx-deployment
```

查看历史记录

```sh
kubectl rollout history deployment nginx-deployment
```

回滚到指定 revision

```sh
kubectl rollout history deployment nginx-deployment --revision=x
```

## 设置容器环境变量

部署一个打印环境变量的 Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: env-dump
spec:
  containers:
  - name: busybox
    image: busybox
    command:
      - env
    env:
    - name: STUDENT_NAME
      value: "Your Name"
    - name: SCHOOL
      value: "Linux Academy"
    - name: KUBERNETES
      value: "is awesome"
```

Pod 执行后，可以通过日志查看环境变量

```sh
$ kubectl logs env-dump
....
STUDENT_NAME=Your Name
SCHOOL=Linux Academy
KUBERNETES=is awesome
....
```

## Pod 扩容

### 命令行方式

用 --replicas=X 扩容 deployment

```sh
$ kubectl get deployment
NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   2         2         2            2           21h
$ kubectl scale deployment nginx-deployment --replicas=3
deployment.extensions/nginx-deployment scaled
$ kubectl get deployment
NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   3         3         3            3           21h
$ kubectl get pod
NAME                                               READY     STATUS      RESTARTS   AGE
...
nginx-deployment-7fc9b7bd96-c6wwh                  1/1       Running     0          21h
nginx-deployment-7fc9b7bd96-kddj5                  1/1       Running     0          31s
nginx-deployment-7fc9b7bd96-s86gc                  1/1       Running     0          21h
```

### yaml 文件方式

修改 yaml 文件中的 `replicas: x`，然后 apply

```sh
kubectl apply -f nginx-deployment.yml
```

## Replication Controller、ReplicaSet 和 Deployment

Deployment 替代了旧的 ReplicationController 功能，但了解原理也很有用。
ReplicationController 保证任意时刻有指定数量的 pod 副本在运行。

以 nginx 容器为例，保持 3 个副本：

### Replication Controller

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    app: nginx
  template:
    metadata:
      name: nginx
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

### ReplicaSet

```yaml
apiVersion: apps/v1beta2
kind: ReplicaSet
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

### Deployment

```yaml
apiVersion: apps/v1beta2 # 1.8.0 之前用 apps/v1beta1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

## Label

给节点打颜色标签

```sh
kubectl label node node1-name color=black
kubectl label node node2-name color=red
kubectl label node node3-name color=green
kubectl label node node4-name color=blue
```

给 default namespace 下所有 pod 打标签

```sh
kubectl label pods -n default color=white --all
```

按标签获取 pod/node 等

```sh
kubectl get pods -l color=white -n default
```

多标签筛选

```sh
kubectl get pods -l color=white,app=nginx
```

## DaemonSet

在所有节点上部署 nginx pod

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: cthulu
  labels:
    daemon: "yup"
spec:
  selector:
    matchLabels:
      daemon: "pod"
  template:
    metadata:
      labels:
        daemon: pod
    spec:
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: cthulu-jr
        image: nginx
```

确认每个节点上 pod 是否运行

```sh
$ kubectl get pod -o wide
NAME                                               READY     STATUS             RESTARTS   AGE       IP              NODE            NOMINATED NODE
cthulu-kvbk9                                       1/1       Running            0          2m        10.1.33.8       juju-cfb27c-2   <none>
cthulu-t7hfc                                       1/1       Running            0          2m        10.1.45.13      juju-cfb27c-1   <none>
cthulu-x8hdf                                       1/1       Running            0          2m        10.1.31.9       juju-cfb27c-3   <none>
```

## 给节点打标签并调度 Pod

给节点打标签

```sh
kubectl label node juju-cfb27c-3 deploy=here
```

yaml 文件中用 `nodeSelector` 指定 pod 部署到特定节点

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
  namespace: default
spec:
  containers:
  - name: busybox
    image: busybox
    command:
      - sleep
      - "300"
    imagePullPolicy: IfNotPresent
  restartPolicy: Always
  nodeSelector:
    deploy: here
```

确认

```sh
$ kubectl get pod busybox -o wide
NAME      READY     STATUS    RESTARTS   AGE       IP           NODE            NOMINATED NODE
busybox   1/1       Running   0          10s       10.1.31.10   juju-cfb27c-3   <none>
```

## 指定调度器

通常不需要在 spec 里指定 schedulerName，但如果要用自定义调度器可以这样写：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: annotation-default-scheduler
  labels:
    name: multischeduler
  annotations:
    scheduledBy: custom-scheduler
spec:
  schedulerName: custom-scheduler
  containers:
  - name: pod-container
    image: k8s.gcr.io/pause:2.0
```

## 日志

查看 pod 当前日志

```sh
kubectl logs pod-name
```

实时查看日志

```sh
kubectl logs pod-name -f
```

只看最后 10 行

```sh
kubectl logs pod-name --tail=10
```

主机/节点上的日志文件在 `/var/log/containers` 目录下

## 节点维护

维护节点时，可以阻止调度新 pod 并驱逐现有 pod（DaemonSet 除外）。

例如将 juju-cfb27c-2 从集群中移除：

```bash
root@juju-cfb27c-0:~# kubectl drain juju-cfb27c-2 --ignore-daemonsets
node/juju-cfb27c-2 cordoned
WARNING: Ignoring DaemonSet-managed pods: cthulu-kvbk9, nginx-ingress-kubernetes-worker-controller-t6qh9
```

juju-cfb27c-2 状态变为 "SchedulingDisabled"

```bash
$ kubectl get node
NAME            STATUS                     ROLES     AGE       VERSION
juju-cfb27c-1   Ready                      <none>    4d        v1.11.2
juju-cfb27c-2   Ready,SchedulingDisabled   <none>    4d        v1.11.2
juju-cfb27c-3   Ready                      <none>    4d        v1.11.2
```

此时可以安全关机维护该节点，新 pod 只会调度到其他节点。

维护完成后恢复节点：

```sh
$ kubectl uncordon juju-cfb27c-2
node/juju-cfb27c-2 uncordoned
$ kubectl get node
NAME            STATUS    ROLES     AGE       VERSION
juju-cfb27c-1   Ready     <none>    4d        v1.11.2
juju-cfb27c-2   Ready     <none>    4d        v1.11.2
juju-cfb27c-3   Ready     <none>    4d        v1.11.2
```

## 升级 Kubernetes 组件

查看当前版本

```sh
kubectl get nodes
```

1. 在 master 节点升级 kubeadm

```sh
sudo apt upgrade kubeadm
```

查看 kubeadm 版本

```sh
kubeadm version
```

1. 查看升级计划

```sh
sudo kubeadm upgrade plan
```

1. 应用升级计划

```sh
sudo kubeadm upgrade apply v1.x.x
```

1. 升级 kubelet

升级前先 drain 目标节点

```sh
kubectl drain NODENAME --ignore-daemonsets
```

手动升级 kubelet

```sh
sudo apt update
sudo apt upgrade kubelet
```

升级后记得恢复节点

```sh
kubectl uncordon NODENAME
```

## 网络

### 入站 Node Port 需求

- Master 节点
  - TCP 6443         --  Kubernetes API Server
  - TCP 2379-2380    --  etcd server client API
  - TCP 10250        --  Kubelet API
  - TCP 10251        --  Kube-scheduler
  - TCP 10252        --  kube-controller-manager
  - TCP 10255        --  Read-only Kubelet API
- Worker 节点
  - TCP 10250        --  Kubelet API
  - TCP 10255        --  Read-only Kubelet API
  - TCP 30000-32767  -- Node Port Services

### 将 Pod 暴露到互联网

```sh
kubectl expost deployment NAME --type="NodePort" --port XX
```

### 部署负载均衡器

```yaml
Kind:Service
apiVersion: v1
metadata:
  name: la-lb-service
spec:
  selector:
    app: la-lb
  ports:
  -  protocol: TCP
     port: 80
     targetPort:9376
  clusterIP: 10.0.171.223
  loadBalancerIP: 78.12.23.17
  type: LoadBalancer

```

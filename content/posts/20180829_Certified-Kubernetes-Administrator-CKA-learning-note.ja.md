---
title: Certified Kubernetes Administrator (CKA) 学習ノート
date: 2018-08-29 11:40:56
tags:
- Kubernetes
- CKA
---

## インストール

1. docker.io のインストール

```sh
apt install docker.io
```

他の cgroup driver で docker をインストールした場合は、docker と Kubernetes が同じ cgroup driver を使うように設定する必要があります。

```sh
cat << EOF >> /etc/docker/daemon.json
{
    "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
```

1. apt キーとソースをシステムに追加

```sh
root@kube-master:~# curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
OK
root@kube-master:~# cat <<EOF >> /etc/apt/sources.list.d/kubernetes.list
> deb http://apt.kubernetes.io/ kubernetes-xenial main
> EOF
```

その後、kubernetes パッケージをインストールします。

```sh
root@kube-master:~# apt update -y
root@kube-master:~# apt install -y kubelet kubeadm kubectl
```

1. kubeadm でセットアップと設定

`kubeadm init` を実行する際、CNI を選択する必要があります。ここでは flannel を選ぶので、`--pod-network-cidr` オプションを追加します。

```sh
root@k8sm:~# kubeadm init --pod-network-cidr=10.244.0.0/16
```

しばらく待つと、インストール完了を示す以下のメッセージが表示されます。

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

指示に従い、通常ユーザーで以下のコマンドを実行します。

```sh
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

また、`kubeadm join` で始まるコマンドをメモしておきましょう。ワーカーノードをクラスターに参加させる際に必要です。

Pod 間の通信のために、Pod ネットワークをインストールする必要があります。ここでは Flannel を使います。

```sh
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

次に、すべてが正常に起動しているか確認します。

```sh
kubectl get pods --all-namespaces
```

coredns-xxxxxx Pod が Running になっていて、master ノードが Ready であれば、クラスターはワーカーノードの参加を受け付ける準備ができています。

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

1. 他のノードをセットアップし、クラスターに参加させる

残りのワーカーノードも、上記と同様に kubectl、kubeadm、kubelet、docker をインストールし、`kubeadm join ...` コマンドを実行します。
しばらくすると、すべてのワーカーノードが Ready になります。

```sh
wshi@k8sm:~$ kubectl get node
NAME      STATUS    ROLES     AGE       VERSION
k8sm      Ready     master    44m       v1.11.2
k8sn1     Ready     <none>    11m       v1.11.2
k8sn2     Ready     <none>    11m       v1.11.2
```

## ジョブの実行

Pod 内で動作するアプリケーションは「ジョブ」と呼ばれます。

ほとんどの Kubernetes オブジェクトは yaml で作成されます。以下は、perl で円周率を2000桁計算して終了するジョブのサンプル yaml です。

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

この yaml ファイルを master ノード上に "pi-job.yaml" という名前で作成し、以下のコマンドでジョブを実行します。

```bash
kubectl create -f pi-job.yaml
```

ジョブの詳細情報は以下のコマンドで確認できます。

```sh
$ kubectl get pod
...
pi-72c7r                                           0/1       Completed   0          3m

$ kubectl describe pod pi-72c7r
...
```

ログ（標準出力）は以下のコマンドで確認できます。

```bash
$ kubectl logs pi-72c7r
3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938446095505822317253594081284811174502841027019385211055596446229489549303819644288109756659334461284756482337867831652712019091456485669234603486104543266482133936072602491412737245870066063155881748815209209628292540917153643678925903600113305305488204665213841469519415116094330572703657595919530921861173819326117931051185480744623799627495673518857527248912279381830119491298336733624406566430860213949463952247371907021798609437027705392171762931767523846748184676694051320005681271452635608277857713427577896091736371787214684409012249534301465495853710507922796892589235420199561121290219608640344181598136297747713099605187072113499999983729780499510597317328160963185950244594553469083026425223082533446850352619311881710100031378387528865875332083814206171776691473035982534904287554687311595628638823537875937519577818577805321712268066130019278766111959092164201989380952572010654858632788659361533818279682303019520353018529689957736225994138912497217752834791315155748572424541506959508295331168617278558890750983817546374649393192550604009277016711390098488240128583616035637076601047101819429555961989467678374494482553797747268471040475346462080466842590694912933136770289891521047521620569660240580381501935112533824300355876402474964732639141992726042699227967823547816360093417216412199245863150302861829745557067498385054945885869269956909272107975093029553211653449872027559602364806654991198818347977535663698074265425278625518184175746728909777727938000816470600161452491921732172147723501414419735685481613611573525521334757418494684385233239073941433345477624168625189835694855620992192221842725502542568876717904946016534668049886272327917860857843838279679766814541009538837863609506800642251252051173929848960841284886269456042419652850222106611863067442786220391949450471237137869609563643719172874677646575739624138908658326459958133904780275898
```

## ジョブの別例

"busybox" イメージを使い、10秒間スリープするジョブのサンプル yaml：

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

## Pod のデプロイ

Pod は通常、Kubernetes クラスター内で稼働するアプリケーションを表します。以下は Pod を定義する yaml の例です：

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

### Pod の起動

```bash
kubectl create -f alpine.yaml
```

### Pod の削除

```bash
kubectl delete -f alpine.yaml
```

または

```sh
kubectl delete pod alpine
```

```sh
kubectl delete pod/alpine
```

## 現在の状態の確認

```sh
kubectl get nodes
kubectl describe node node-name
kubectl get pods --all-namespaces -o wide
```

`-n` オプションで namespace を指定できます。

```sh
kubectl get pods -n kube-system
```

## Deployment

nginx デプロイメント用の yaml ファイル例：

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

### デプロイメントと Pod の作成

```sh
kubectl create -f nginx-deployment.yaml
```

詳細情報の取得

```sh
kubectl describe deployment nginx-deployment
```

Pod がどのノードで稼働しているか確認

```sh
$ kubectl get pod nginx-deployment-7fc9b7bd96-c6wwh -o wide
NAME                                READY     STATUS    RESTARTS   AGE       IP          NODE            NOMINATED NODE
nginx-deployment-7fc9b7bd96-c6wwh   1/1       Running   0          21h       10.1.33.6   juju-cfb27c-2   <none>
```

### イメージバージョンのロールアウト

イメージバージョンを1.8に変更するには、以下のコマンドを実行

```sh
kubectl set image deployment nginx-deployment nginx=nginx:1.8
```

または、yaml のイメージバージョンを1.8に書き換えて apply

```sh
kubectl apply -f nginx-deployment.yaml
```

ロールアウトの状態確認

```sh
kubectl rollout status deployment nginx-deployment
```

前回のロールアウトを元に戻す

```sh
kubectl rollout undo deployment nginx-deployment
```

履歴の表示

```sh
kubectl rollout history deployment nginx-deployment
```

特定のリビジョンに戻す

```sh
kubectl rollout history deployment nginx-deployment --revision=x
```

## コンテナ環境変数の設定

環境変数を出力する Pod のデプロイ例

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

Pod 実行後、ログで環境変数を確認

```sh
$ kubectl logs env-dump
....
STUDENT_NAME=Your Name
SCHOOL=Linux Academy
KUBERNETES=is awesome
....
```

## Pod のスケーリング

### コマンドライン

--replicas=X でデプロイメントをスケール

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

### yaml ファイル

yaml の `replicas: x` を変更し、apply

```sh
kubectl apply -f nginx-deployment.yml
```

## Replication Controller, ReplicaSet, Deployment

Deployment は古い ReplicationController の機能を置き換えましたが、知っておいて損はありません。
ReplicationController は、指定した数の Pod レプリカが常に稼働していることを保証します。

nginx コンテナを3つ維持する例：

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
apiVersion: apps/v1beta2 # 1.8.0以前は apps/v1beta1
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

## ラベル

ノードに色ラベルを付与

```sh
kubectl label node node1-name color=black
kubectl label node node2-name color=red
kubectl label node node3-name color=green
kubectl label node node4-name color=blue
```

default namespace の全 Pod にラベル付与

```sh
kubectl label pods -n default color=white --all
```

特定ラベルの Pod/ノード取得

```sh
kubectl get pods -l color=white -n default
```

複数ラベルで取得

```sh
kubectl get pods -l color=white,app=nginx
```

## DaemonSet

全ノードに nginx Pod をデプロイ

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

各ノードで Pod が稼働しているか確認

```sh
$ kubectl get pod -o wide
NAME                                               READY     STATUS             RESTARTS   AGE       IP              NODE            NOMINATED NODE
cthulu-kvbk9                                       1/1       Running            0          2m        10.1.33.8       juju-cfb27c-2   <none>
cthulu-t7hfc                                       1/1       Running            0          2m        10.1.45.13      juju-cfb27c-1   <none>
cthulu-x8hdf                                       1/1       Running            0          2m        10.1.31.9       juju-cfb27c-3   <none>
```

## ノードにラベルを付けて Pod をスケジューリング

ノードにラベルを付与

```sh
kubectl label node juju-cfb27c-3 deploy=here
```

yaml の `nodeSelector` で特定ノードに Pod を配置

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

確認

```sh
$ kubectl get pod busybox -o wide
NAME      READY     STATUS    RESTARTS   AGE       IP           NODE            NOMINATED NODE
busybox   1/1       Running   0          10s       10.1.31.10   juju-cfb27c-3   <none>
```

## 特定スケジューラー

通常は spec で schedulerName を指定しませんが、カスタムスケジューラーを使いたい場合は指定します。

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

## ログ

Pod の現在のログを表示

```sh
kubectl logs pod-name
```

インタラクティブにログを表示

```sh
kubectl logs pod-name -f
```

最後の10行だけ表示

```sh
kubectl logs pod-name --tail=10
```

マスター/ノードのログファイルは `/var/log/containers` にあります。

## ノードメンテナンス

ノードをメンテナンスするには、スケジューラーが新しい Pod を配置しないようにし、既存の Pod を退避させます（DaemonSet は除外）。

例：juju-cfb27c-2 をクラスターから外す

```bash
root@juju-cfb27c-0:~# kubectl drain juju-cfb27c-2 --ignore-daemonsets
node/juju-cfb27c-2 cordoned
WARNING: Ignoring DaemonSet-managed pods: cthulu-kvbk9, nginx-ingress-kubernetes-worker-controller-t6qh9
```

juju-cfb27c-2 は "SchedulingDisabled" になります

```bash
$ kubectl get node
NAME            STATUS                     ROLES     AGE       VERSION
juju-cfb27c-1   Ready                      <none>    4d        v1.11.2
juju-cfb27c-2   Ready,SchedulingDisabled   <none>    4d        v1.11.2
juju-cfb27c-3   Ready                      <none>    4d        v1.11.2
```

この状態で -2 ノードをシャットダウンしてメンテナンスできます。新しい Pod は他のノードにのみ配置されます。

メンテナンス後、ノードを復帰させるには

```sh
$ kubectl uncordon juju-cfb27c-2
node/juju-cfb27c-2 uncordoned
$ kubectl get node
NAME            STATUS    ROLES     AGE       VERSION
juju-cfb27c-1   Ready     <none>    4d        v1.11.2
juju-cfb27c-2   Ready     <none>    4d        v1.11.2
juju-cfb27c-3   Ready     <none>    4d        v1.11.2
```

## Kubernetes コンポーネントのアップグレード

現在のバージョン確認

```sh
kubectl get nodes
```

1. master ノードで kubeadm をアップグレード

```sh
sudo apt upgrade kubeadm
```

kubeadm のバージョン確認

```sh
kubeadm version
```

1. アップグレードプランの確認

```sh
sudo kubeadm upgrade plan
```

1. アップグレードプランの適用

```sh
sudo kubeadm upgrade apply v1.x.x
```

1. kubelet のアップグレード

アップグレード前に、対象ノードを drain

```sh
kubectl drain NODENAME --ignore-daemonsets
```

kubelet を手動でアップデート

```sh
sudo apt update
sudo apt upgrade kubelet
```

アップグレード後、ノードを復帰させるのを忘れずに

```sh
kubectl uncordon NODENAME
```

## ネットワーク

### インバウンド Node Port 要件

- マスターノード
  - TCP 6443         --  Kubernetes API Server
  - TCP 2379-2380    --  etcd server client API
  - TCP 10250        --  Kubelet API
  - TCP 10251        --  Kube-scheduler
  - TCP 10252        --  kube-controller-manager
  - TCP 10255        --  Read-only Kubelet API
- ワーカーノード
  - TCP 10250        --  Kubelet API
  - TCP 10255        --  Read-only Kubelet API
  - TCP 30000-32767  -- Node Port Services

### Pod をインターネットに公開

```sh
kubectl expost deployment NAME --type="NodePort" --port XX
```

### ロードバランサーのデプロイ

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

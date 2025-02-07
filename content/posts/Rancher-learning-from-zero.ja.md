---
title: "Rancher ゼロから勉強 "
date: 2020-06-09T16:12:08+09:00
draft: false
---

# 紹介

Rancherは`rancher-server` と`rancher-agent`、そして一つ以上の`kubernetes cluster`によって構成されている。この中、`rancher-agent`は管理された`kubernetes`に実行され、`rancher-server`と通信し、クラスタの情報を送信する。

 `rancher-server`は`kubernetes`を管理するためのWebUIとAPIを提供している。`rancher-server`はHTTPSのみアクセスできる。

# インストール

## シングルノード

シングルノードの構築は以下二つの方法があります。

-  `docker`で直接`rancher-server`を実行
- `rke`で一つのノードに全ての`role`を有効

`rke`の方法は後でも出てくるので割愛、ここでは`docker`の方法を示す。

`rancher-server`を実行したいノードで、下記のコマンドを入力する。

```bash
docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  rancher/rancher:latest
```

これでシングルノードの`rancher-server`を起動した。`http://<IP Address>`でアクセスできる。

## マルチノード

`rke`を使ってHA環境の`rancher-server`を構築する。

`rke(rancher k8s engine)`は`kubernetes`を構築するためのコマンドで、環境を用意すればコマンド一つでクラスターを構築できる。

### マシンの用意

今回は`multipass` でマシンを準備する。以下のコマンドで６台の仮想マシンを作成する。

```bash
multipass launch -c 2 -m 4096M -d 20G --cloud-init=./cloud-init.yaml -n kmaster1
multipass launch -c 2 -m 4096M -d 20G --cloud-init=./cloud-init.yaml -n kmaster2
multipass launch -c 2 -m 4096M -d 20G --cloud-init=./cloud-init.yaml -n kmaster3
multipass launch -c 2 -m 4096M -d 20G --cloud-init=./cloud-init.yaml -n kworker1
multipass launch -c 2 -m 4096M -d 20G --cloud-init=./cloud-init.yaml -n kworker2
multipass launch -c 2 -m 4096M -d 20G --cloud-init=./cloud-init.yaml -n kworker3
```

コマンドにあった`cloud-init.yaml`ファイルは、マシン立ち上がった後の後処理を実行する。今回の場合は以下の後処理を実行した。

- `docker`のインストール

- ホストマシン`ssh`キーの登録
- `Ubuntu`ユーザを`docker`グループに登録
- 必要カーネルモジュールのロード
- swap領域の停止

詳細の内容は以下に示す。

```cloud-init
#cloud-config

packages:
    - docker.io

ssh_authorized_keys:
    - <rsa public key>

runcmd:
    - usermod -aG docker ubuntu
    - modprobe br_netfilter
    - modprobe ip6_udp_tunnel
    - modprobe ip_set
    - modprobe ip_set_hash_ip
    - modprobe ip_set_hash_net
    - modprobe iptable_filter
    - modprobe iptable_nat
    - modprobe iptable_mangle
    - modprobe iptable_raw
    - modprobe nf_conntrack_netlink
    - modprobe nf_conntrack
    - modprobe nf_conntrack_ipv4
    - modprobe nf_defrag_ipv4
    - modprobe nf_nat
    - modprobe nf_nat_ipv4
    - modprobe nf_nat_masquerade_ipv4
    - modprobe nfnetlink
    - modprobe udp_tunnel
    - modprobe veth
    - modprobe vxlan
    - modprobe x_tables
    - modprobe xt_addrtype
    - modprobe xt_conntrack
    - modprobe xt_comment
    - modprobe xt_mark
    - modprobe xt_multiport
    - modprobe xt_nat
    - modprobe xt_recent
    - modprobe xt_set
    - modprobe xt_statistic
    - modprobe xt_tcpudp
    - swapoff -a
```

最終的に以下ようにな６台のマシンができた

```
$ multipass list
Name                    State             IPv4             Image
kmaster1                Running           10.131.158.97    Not Available
kmaster2                Running           10.131.158.194   Not Available
kmaster3                Running           10.131.158.121   Not Available
kworker1                Running           10.131.158.133   Not Available
kworker2                Running           10.131.158.247   Not Available
kworker3                Running           10.131.158.166   Not Available
```

### rkeでKubernetes環境作成

[rke](https://rancher.com/products/rke/)で説明した通り、バイナリをダウンロードし実行権限を追加する。

上記の６ノードの情報とそれぞれの役割を設定する。他にもいろいろ設定できるが、今回は割愛

```yaml
nodes:
  - address: 10.131.158.97
    user: ubuntu
    role: [controlplane, worker, etcd]
  - address: 10.131.158.194
    user: ubuntu
    role: [controlplane, worker, etcd]
  - address: 10.131.158.121
    user: ubuntu
    role: [controlplane, worker, etcd]
  - address: 10.131.158.133
    user: ubuntu
    role: [worker]
  - address: 10.131.158.247
    user: ubuntu
    role: [worker]
  - address: 10.131.158.166
    user: ubuntu
    role: [worker]

system-images:
    kubernetes: rancher/hyperkube:v1.18.2

services:
  etcd:
    snapshot: true
    creation: 6h
    retention: 24

ingress:
  provider: nginx
  options:
    use-forwarded-headers: 'true'
```

`rke`コマンドにこの`Yamlファイルをパラメータにして実行すると、Kubernetes環境が作成できる。

```
rke_linux-amd64 up --config ./rancher_cluster.yaml
```



無事クラスタが作成された後、元のYamlファイル以外に、新しいファイルが二つ生成されます。

```
$ ll
total 132K
-rw-r----- 1 wshi wshi 5.3K Jun  8 17:04 kube_config_rancher_cluster.yaml
-rw-r----- 1 wshi wshi 119K Jun  8 17:07 rancher_cluster.rkestate
-rw-rw-r-- 1 wshi wshi  748 Jun  8 16:53 rancher_cluster.yaml
```

この中の`kube_config_rancher_cluster.yaml`はクラスタにアクセスするための設定ファイルのため、`kubectl`に読み込まれるように、`~/kube/config`にコピーする。これによってクラスタにアクセスができるようになった。

```bash
$ kubectl get node
NAME             STATUS   ROLES                      AGE   VERSION
10.131.158.121   Ready    controlplane,etcd,worker   21h   v1.17.4
10.131.158.133   Ready    worker                     21h   v1.17.4
10.131.158.166   Ready    worker                     21h   v1.17.4
10.131.158.194   Ready    controlplane,etcd,worker   21h   v1.17.4
10.131.158.247   Ready    worker                     21h   v1.17.4
10.131.158.97    Ready    controlplane,etcd,worker   21h   v1.17.4
```

### kubenetes環境でRancherをインストール

[rancherのドキュメント](https://rancher.com/docs/rancher/v2.x/en/installation/k8s-install/helm-rancher/) に従ってインストールします。ここではインストールの手順だけ抽出し、詳しい設定はドキュメントを参照してください。

1. `helm`のインストール

   [helmのホームページ](https://helm.sh/docs/intro/install/)を参考にして`helm`をインストールする

   ```
   sudo snap install helm --classic
   ```

2. `helm`に`rancher`のリポジトリを追加

   今回は`stable`を選択する

   ```
   helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
   ```

3. `rancher`インストールのため`namespace`を追加

   `namespace`の名前は必ず`cattle-system`にする

   ```
   kubectl create namespace cattle-system
   ```

4. `cert-manager`をインストール

   他にも証明書作成の方法はありますが、今回は`rancher`に生成してもらう

   ```
   # Install the CustomResourceDefinition resources separately
   kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.0/cert-manager.crds.yaml

   # Create the namespace for cert-manager
   kubectl create namespace cert-manager

   # Add the Jetstack Helm repository
   helm repo add jetstack https://charts.jetstack.io

   # Update your local Helm chart repository cache
   helm repo update

   # Install the cert-manager Helm chart
   helm install \
     cert-manager jetstack/cert-manager \
     --namespace cert-manager \
     --version v0.15.0
   ```

   `cert-manager`の状態を確認

   ```
   $ kubectl get pods --namespace cert-manager
   NAME                                       READY   STATUS    RESTARTS   AGE
   cert-manager-766d5c494b-9cmcq              1/1     Running   0          15s
   cert-manager-cainjector-6649bbb695-cfmxq   1/1     Running   0          15s
   cert-manager-webhook-68d464c8b-5bmjt       1/1     Running   0          15s
   ```



5. `rancher-server`をインストール

   Rancher-generated certificatesを利用して、`rancher-server`をインストール

   ```
   helm install rancher rancher-stable/rancher \
     --namespace cattle-system \
     --set hostname=rancher.my.org
   ```

   `rancher-server`の状態を確認

   ```
   $ kubectl get pod -n cattle-system -o wide
   NAME                       READY   STATUS    RESTARTS   AGE   IP          NODE             NOMINATED NODE   READINESS GATES
   rancher-756b996499-fjnt9   1/1     Running   0          35m   10.42.0.4   10.131.158.247   <none>           <none>
   rancher-756b996499-rkn8h   1/1     Running   0          35m   10.42.2.4   10.131.158.121   <none>           <none>
   rancher-756b996499-wmczg   1/1     Running   0          35m   10.42.5.4   10.131.158.97    <none>           <none>

   ```

   それぞれのノード上にPodが`Running`状態であり、インストールは成功した。


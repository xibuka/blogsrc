---
title: RancherのContinuous Delivery機能で簡単GitOpsを実現できる
date: 2021-11-11T16:18:38+09:00
draft: false
---

この記事では、Single nodeのRancher server と二つのk3sクラスタ環境を構築し、 そRancherのContinuous Delivery機能で、二つのk3sクラスタをGitOpsで操作します。

## Step 1: Deploying a Rancher Server

まずはrancherノードで、以下のdocker コマンドを実行しSingle nodeのRancher serverを構築します。

```ctr:rancher
sudo docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  --privileged \
  rancher/rancher:v2.5.10
```

Rancher serverが1分程度で立ち上がりますので、rancherノードのIPアドレスをブラウザで開いてRancher UIをアクセスしてください。

今回の場合、Rancherは自己署名証明書を使用しているため、ブラウザに証明書の警告が表示されます。この警告はスキップしても問題ありません。 また、一部のブラウザでは、スキップボタンが表示されない場合があります。 この場合は、エラーページの任意の場所をクリックして、`thisisunsafe`と入力します。 これにより、ブラウザは警告をバイパスして証明書を受け入れるようになります。

初回アクセスの時パスワードの初期設定が必要です。画面のガイドに従って設定してください。

## Step 2: Deploy k3s Kubernetes Cluster

次はk3sクラスタをデプロイします。手順はとても簡単で、以下のコマンドをk3s-1とk3s-2ノードで実行するだけです。

後でアップグレードもやる予定なので、ここではあえてちょっと古いバージョンを指定しk3sのクラスタをデプロイします。

### k3s-1

```bash
sudo curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.19.15+k3s2 sh -
```

### k3s-2

```bash
sudo curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.19.15+k3s2 sh -
```

デプロイが完了したら、以下のコマンドでクラスタを確認してください。

```bash
sudo kubectl get node
```

Note: K3sは`root`ユーザの操作を想定しているので`sudo` 権限が必要です。

## Step 3: Add k3s cluster to Rancher

次はk3sクラスタをRancher にImportします。 以下の手順で、k3s-1を登録してください。

1. RancherのGlobal画面で、右側にある`Add Cluster` をクリックし、`Other Cluster`を選択してください。![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lf9ujojj31km0iawgw.jpg)![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lho6paqj31ks0n4tbo.jpg)
2. Cluster Nameにクラスタの名前　`k3s-1`　を入力し`Create`をクリックします。
3. `curl...`から始まっているコマンドをクリックし、k3s-1のノードで実行してください。![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0li59ccij311t0u0wjw.jpg)

同じ手順で、`k3s-2`を登録してください。

## Step 4: Cluster Group

ここから、Continuous Deliveryの操作に入ります。 Global画面の`Tools`->`Continous Delivery`を選択してください。

まずは`Cluster Group`を作成します。左側の`Cluster Group`メニューに入り、画面右側にある`Create`をクリックし、`Cluster Group`作成メニューに入ります。 ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0litcf2xj31l80jm76u.jpg)

今回は`k3s`を使ってデモするので、Nameのところを`k3s-demo`に入力します。

次は重要なところです。`Cluster Group`の所属は設定されたラベルを持つクラスタを選択するので、ここでは`Add Rule`をクリックしてラベルを設定します。今回のDemoでは、K3sを使っているので、`Cluster Selectors`のところに `k3s=true` のラベルを設定します。

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0ljfi55gj311g0u00ve.jpg)

上記の設定が終わったら`Create`をクリックし`Cluster Group`の作成が終了します。

------

次はimportされた2機のk3sクラスタをこの`Cluster Group`にアサインします。左側の`Clusters`メニューに入り、まずは`k3s-1`のクラスタの右側にある︙をクリックし、`Assign to`を選択します。 ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lk1pfikj31fx0u0tc8.jpg)

`Add/Set Label`をクリックし、さっき設定したラベル`k3s=true`を設定し、`Apply`をクリックします。これでこのクラスタがさっき作成したクラスタグループに配属されました。 ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lkuljntj31l80ls40e.jpg)

同じ手順で`k3s-2`のクラスタも`Cluster Group`に配属しましょう。`Cluster Groups`画面から`Clusters Ready`が`２`になっていることが分かります。 ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0llk63cvj31dt0u0dk3.jpg)

## Step 5: Git Repos

このステップでは、参照する`Git Repo`の設定を行います。左側の`Git Repos`に入り、画面右側にある`Create`をクリックし、`Git Repos`作成画面に入ります。 ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lna46oqj31lm0j4mzo.jpg) 名前を入力した後、各自のGithubのアカウントで https://github.com/rancher/fleet-examples をfolkし、Repository URL(e.g. https://github.com/xibuka/fleet-examples.git )に設定してください。 また、`Paths`に今回利用する`guest-book`の定義ファイルが置いてあった `/single-cluster/manifests` を設定して ください。 次はこの`Git Repos`をどこにデプロイするのかを設定します。`Deploy To`のメニューから、さっき作成した`Cluster Group`を選択し、`Create`をクリックしてください。

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lnq6olrj30u010jdiu.jpg)

これで、k3s-1とk3s-2に`guest-book`のリソースがデプロイされます。 ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lorwtfdj31si0jujut.jpg)

------

次に、deployment以下に新しいファイル`nginx.yaml`を追加しましょう。以下の内容で追加したら、Continuous Deliveryがこのファイルを検知し、`Cluster Group`にデプロイします。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 1
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
        image: nginx:1.21
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 32000
```

デプロイが完了したら、クラスタ側で`Pod`や`Service`などを確認しましょう。 ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lpcvw6rj31sc0jg0w4.jpg) ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lqbftl3j31mz0u0grg.jpg)

同じく、監視先のファイルに変更がある場合も、その修正内容は随時`cluster group`にデプロイされます。 試しに、上記のYAMLの以下の２行を変更してみてください。

```yaml
...
        image: nginx:1.20
...
    nodePort: 31000
```

修正内容が反映されました。

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lqvplo3j31s20i0dj4.jpg)

## Step 6: Deploy Application

このステップでは、Git Repoの登録からRancherのアップリケーションをデプロイします。

まずはRepository URLに、https://github.com/xibuka/core-bundles.gitを設定し、`Add Path`で以下の二つのパスを追加します。

- /longhorn
- /longhorn-crd![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lrrgmr1j30zz0u0gog.jpg)

`Create`をクリックしたら定義したアップリケーションがデプロイされます。

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lsbl6bnj31sc0nkaem.jpg) ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lsl6bt5j31si0gaq4v.jpg)

## Step 7: Upgrade

このステップでは、Git Repoの登録から二つのk3sクラスタをアップグレードします。アップグレードを実現するために、以下のAutomated Upgrades機能を利用します。

https://rancher.com/docs/k3s/latest/en/upgrades/automated/

まずはこの機能に必要なリソースを準備します。以下のコマンドを一回ずつクリックし各クラスタで実行させてください。

```bash
sudo kubectl apply -f https://github.com/rancher/system-upgrade-controller/releases/download/v0.6.2/system-upgrade-controller.yaml
sudo kubectl apply -f https://github.com/rancher/system-upgrade-controller/releases/download/v0.6.2/system-upgrade-controller.yaml
```

次は https://github.com/xibuka/k3s-upgrade-plan をfolkし、Git reposを設定してください。Branch Nameを`Main`にして、`Create`をクリックしてください。 `/` 以下が対象なので`path`の追加が必要ないです。 ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lt2yhh2j313l0u077f.jpg)

現在のk3sのバージョンは　1.21.5+k3s2　であることを確認します。 ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lu2ele4j31s00hmwhk.jpg)

Git ReposにあるPlanのファイルを変更し、versionを`1.22.2+k3s1`に変更しcommitしてください。少し時間が立つと二つのk3sクラスタのバージョンは1.22.2にアップグレードされるはずです。

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0luf74qvj31sk0qqtdd.jpg) ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lugbm2yj31ry0i4q5w.jpg)

FleetのDemoはここまでですが、まだまだ使える機能はたくさんありますので探してみてください。

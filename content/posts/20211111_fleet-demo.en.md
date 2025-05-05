---
title: Achieve Easy GitOps with Rancher's Continuous Delivery Feature
date: 2021-11-11T16:18:38+09:00
draft: false
tags: 
- Rancher
- Fleet
---

This article builds a single-node Rancher server and two k3s cluster environments, and uses Rancher's Continuous Delivery feature to operate both k3s clusters via GitOps.

## Step 1: Deploying a Rancher Server

First, on the rancher node, run the following docker command to set up a single-node Rancher server.

```ctr:rancher
sudo docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  --privileged \
  rancher/rancher:v2.5.10
```

The Rancher server will start in about a minute. Open the Rancher node's IP address in your browser to access the Rancher UI.

Since Rancher uses a self-signed certificate in this case, your browser will show a certificate warning. You can safely skip this warning. In some browsers, the skip button may not appear. In that case, click anywhere on the error page and type `thisisunsafe`. This will bypass the warning and accept the certificate.

On first access, you need to set an initial password. Follow the on-screen instructions to set it up.

## Step 2: Deploy k3s Kubernetes Cluster

Next, deploy the k3s clusters. The procedure is very simple: just run the following command on both the k3s-1 and k3s-2 nodes.

Since we plan to upgrade later, we'll intentionally deploy an older version of k3s here.

### k3s-1

```bash
sudo curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.19.15+k3s2 sh -
```

### k3s-2

```bash
sudo curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.19.15+k3s2 sh -
```

After deployment, check the cluster with the following command:

```bash
sudo kubectl get node
```

Note: K3s assumes operations as the `root` user, so `sudo` privileges are required.

## Step 3: Add k3s cluster to Rancher

Next, import the k3s clusters into Rancher. Follow these steps to register k3s-1:

1. In Rancher's Global view, click `Add Cluster` on the right, then select `Other Cluster`. ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lf9ujojj31km0iawgw.jpg)![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lho6paqj31ks0n4tbo.jpg)
2. Enter the cluster name `k3s-1` and click `Create`.
3. Click the command starting with `curl...` and run it on the k3s-1 node. ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0li59ccij311t0u0wjw.jpg)

Register `k3s-2` in the same way.

## Step 4: Cluster Group

Now, let's start using Continuous Delivery. In the Global view, select `Tools` -> `Continuous Delivery`.

First, create a `Cluster Group`. Go to the `Cluster Group` menu on the left, click `Create` on the right, and enter the `Cluster Group` creation menu. ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0litcf2xj31l80jm76u.jpg)

We'll use `k3s` for this demo, so enter `k3s-demo` as the Name.

Next is an important step. The `Cluster Group` selects clusters with the specified label, so click `Add Rule` and set a label. For this demo, since we're using K3s, set the `Cluster Selectors` label to `k3s=true`.

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0ljfi55gj311g0u00ve.jpg)

After setting, click `Create` to finish creating the `Cluster Group`.

------

Next, assign the two imported k3s clusters to this `Cluster Group`. Go to the `Clusters` menu on the left, click the ︙ next to `k3s-1`, and select `Assign to`. ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lk1pfikj31fx0u0tc8.jpg)

Click `Add/Set Label`, set the label `k3s=true` as before, and click `Apply`. Now this cluster is assigned to the group you just created. ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lkuljntj31l80ls40e.jpg)

Do the same for `k3s-2`. On the `Cluster Groups` screen, you should see `Clusters Ready` as `2`. ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0llk63cvj31dt0u0dk3.jpg)

## Step 5: Git Repos

In this step, set up the `Git Repo` to reference. Go to `Git Repos` on the left, click `Create` on the right, and enter the `Git Repos` creation screen. ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lna46oqj31lm0j4mzo.jpg) After entering a name, fork `https://github.com/rancher/fleet-examples` with your Github account, and set the Repository URL (e.g. `https://github.com/xibuka/fleet-examples.git` ). Also, set `Paths` to `/single-cluster/manifests` where the `guest-book` definition files are located. Next, set where to deploy this `Git Repos`. From the `Deploy To` menu, select the `Cluster Group` you created earlier and click `Create`.

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lnq6olrj30u010jdiu.jpg)

Now, the `guest-book` resources will be deployed to both k3s-1 and k3s-2. ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lorwtfdj31si0jujut.jpg)

------

Next, add a new file `nginx.yaml` under `deployment`. After adding the following content, Continuous Delivery will detect this file and deploy it to the `Cluster Group`.

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

After deployment, check the `Pod` and `Service` on the cluster. ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lpcvw6rj31sc0jg0w4.jpg) ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lqbftl3j31mz0u0grg.jpg)

Similarly, if there are changes to the monitored files, those changes will be deployed to the `cluster group` as well. Try changing the following two lines in the YAML above:

```yaml
...
        image: nginx:1.20
...
    nodePort: 31000
```

The changes are reflected.

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lqvplo3j31s20i0dj4.jpg)

## Step 6: Deploy Application

In this step, register a Git Repo and deploy a Rancher application.

Set the Repository URL to `https://github.com/xibuka/core-bundles.git`, and add the following two paths with `Add Path`:

- /longhorn
- /longhorn-crd ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lrrgmr1j30zz0u0gog.jpg)

Click `Create` and the defined application will be deployed.

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lsbl6bnj31sc0nkaem.jpg) ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lsl6bt5j31si0gaq4v.jpg)

## Step 7: Upgrade

In this step, register a Git Repo and upgrade both k3s clusters. To perform the upgrade, use the Automated Upgrades feature below.

[https://rancher.com/docs/k3s/latest/en/upgrades/automated/](https://rancher.com/docs/k3s/latest/en/upgrades/automated/)

First, prepare the resources needed for this feature. Click and run the following commands one by one on each cluster.

```bash
sudo kubectl apply -f https://github.com/rancher/system-upgrade-controller/releases/download/v0.6.2/system-upgrade-controller.yaml
sudo kubectl apply -f https://github.com/rancher/system-upgrade-controller/releases/download/v0.6.2/system-upgrade-controller.yaml
```

Next, fork `https://github.com/xibuka/k3s-upgrade-plan` and set up the Git repos. Set the Branch Name to `Main` and click `Create`. Since everything under `/` is targeted, you don't need to add a path. ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lt2yhh2j313l0u077f.jpg)

Check that the current k3s version is 1.21.5+k3s2. ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lu2ele4j31s00hmwhk.jpg)

Change the version in the Plan file in the Git Repos to `1.22.2+k3s1` and commit. After a while, both k3s clusters should be upgraded to version 1.22.2.

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0luf74qvj31sk0qqtdd.jpg) ![img](https://tva1.sinaimg.cn/large/008i3skNgy1gw0lugbm2yj31ry0i4q5w.jpg)

That's it for the Fleet demo, but there are still many more features to explore, so give them a try!

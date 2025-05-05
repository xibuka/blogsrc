---
title: "Learning Rancher from Zero"
date: 2020-06-09T16:12:08+09:00
draft: false
---

## Introduction

Rancher consists of `rancher-server`, `rancher-agent`, and one or more `kubernetes clusters`. Among these, `rancher-agent` runs on the managed `kubernetes` and communicates with the `rancher-server`, sending cluster information.

The `rancher-server` provides a WebUI and API for managing `kubernetes`. The `rancher-server` is accessible only via HTTPS.

## Installation

### Single Node

There are two ways to build a single-node setup:

- Run `rancher-server` directly with `docker`
- Use `rke` to enable all `roles` on a single node

The `rke` method will be described later, so here we show the `docker` method.

On the node where you want to run `rancher-server`, enter the following command:

```bash
docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  rancher/rancher:latest
```

This will start a single-node `rancher-server`. You can access it at `http://<IP Address>`.

### Multi Node

Use `rke` to build an HA environment for `rancher-server`.

`rke (rancher k8s engine)` is a command-line tool for building `kubernetes` clusters. Once the environment is ready, you can build a cluster with a single command.

#### Prepare Machines

This time, we use `multipass` to prepare the machines. The following commands create six virtual machines:

```bash
multipass launch -c 2 -m 4096M -d 20G --cloud-init=./cloud-init.yaml -n kmaster1
multipass launch -c 2 -m 4096M -d 20G --cloud-init=./cloud-init.yaml -n kmaster2
multipass launch -c 2 -m 4096M -d 20G --cloud-init=./cloud-init.yaml -n kmaster3
multipass launch -c 2 -m 4096M -d 20G --cloud-init=./cloud-init.yaml -n kworker1
multipass launch -c 2 -m 4096M -d 20G --cloud-init=./cloud-init.yaml -n kworker2
multipass launch -c 2 -m 4096M -d 20G --cloud-init=./cloud-init.yaml -n kworker3
```

The `cloud-init.yaml` file referenced in the command performs post-setup tasks after the machine boots. In this case, the following tasks are performed:

- Install `docker`
- Register the host machine's `ssh` key
- Add the `Ubuntu` user to the `docker` group
- Load required kernel modules
- Disable swap

The details are as follows:

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

In the end, you will have six machines as follows:

```bash
$ multipass list
Name                    State             IPv4             Image
kmaster1                Running           10.131.158.97    Not Available
kmaster2                Running           10.131.158.194   Not Available
kmaster3                Running           10.131.158.121   Not Available
kworker1                Running           10.131.158.133   Not Available
kworker2                Running           10.131.158.247   Not Available
kworker3                Running           10.131.158.166   Not Available
```

#### Create Kubernetes Environment with rke

As described in [rke](https://rancher.com/products/rke/), download the binary and add execute permission.

Set the information and roles for the above six nodes. Many other settings are possible, but they are omitted here.

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

Run the `rke` command with this yaml file as a parameter to create the Kubernetes environment.

```sh
rke_linux-amd64 up --config ./rancher_cluster.yaml
```

After the cluster is successfully created, two new files will be generated in addition to the original yaml file.

```bash
$ ll
total 132K
-rw-r----- 1 wshi wshi 5.3K Jun  8 17:04 kube_config_rancher_cluster.yaml
-rw-r----- 1 wshi wshi 119K Jun  8 17:07 rancher_cluster.rkestate
-rw-rw-r-- 1 wshi wshi  748 Jun  8 16:53 rancher_cluster.yaml
```

Among these, `kube_config_rancher_cluster.yaml` is the configuration file for accessing the cluster. Copy it to `~/kube/config` so that it can be loaded by `kubectl`. Now you can access the cluster.

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

#### Install Rancher on Kubernetes

Follow the [Rancher documentation](https://rancher.com/docs/rancher/v2.x/en/installation/k8s-install/helm-rancher/) for installation. Here, only the installation steps are extracted; for detailed settings, refer to the documentation.

1. Install `helm`

   Refer to the [helm homepage](https://helm.sh/docs/intro/install/) to install `helm`.

   ```bash
   sudo snap install helm --classic
   ```

2. Add the `rancher` repository to `helm`

   This time, select `stable`.

   ```bash
   helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
   ```

3. Add a `namespace` for installing `rancher`

   The namespace name must be `cattle-system`.

   ```bash
   kubectl create namespace cattle-system
   ```

4. Install `cert-manager`

   There are other ways to create certificates, but here we let `rancher` generate them.

   ```bash
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

   Check the status of `cert-manager`:

   ```bash
   $ kubectl get pods --namespace cert-manager
   NAME                                       READY   STATUS    RESTARTS   AGE
   cert-manager-766d5c494b-9cmcq              1/1     Running   0          15s
   cert-manager-cainjector-6649bbb695-cfmxq   1/1     Running   0          15s
   cert-manager-webhook-68d464c8b-5bmjt       1/1     Running   0          15s
   ```

5. Install `rancher-server`

   Install `rancher-server` using Rancher-generated certificates.

   ```bash
   helm install rancher rancher-stable/rancher \
     --namespace cattle-system \
     --set hostname=rancher.my.org
   ```

   Check the status of `rancher-server`:

   ```bash
   $ kubectl get pod -n cattle-system -o wide
   NAME                       READY   STATUS    RESTARTS   AGE   IP          NODE             NOMINATED NODE   READINESS GATES
   rancher-756b996499-fjnt9   1/1     Running   0          35m   10.42.0.4   10.131.158.247   <none>           <none>
   rancher-756b996499-rkn8h   1/1     Running   0          35m   10.42.2.4   10.131.158.121   <none>           <none>
   rancher-756b996499-wmczg   1/1     Running   0          35m   10.42.5.4   10.131.158.97    <none>           <none>

   ```

   Pods on each node are in `Running` state, indicating successful installation.

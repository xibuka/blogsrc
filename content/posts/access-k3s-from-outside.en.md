---
title: "Access K3s From Outside"
date: 2022-03-03T23:49:19+09:00
draft: false
---

# Access k3s cluster from outside

When you have created a k3s cluster with the default settings, it only can be access inside the node where you're using.
Bring the kubeconfig file `/etc/rancher/k3s/k3s.yaml` outside the node and import it to another host, you will get below issue when trying to access.

```bash
❯ kubectl get node
Unable to connect to the server: x509: certificate is valid for 10.0.140.68, 10.43.0.1, 127.0.0.1, not xxx.xxx.xxx.xxx
```

To make it possible for access k3s cluster outside the node, you can use the below parameter when create the cluster.

```bash
--tls-san value                            (listener) Add additional hostname or IP as a Subject Alternative Name in the TLS cert
```

for details of this parameter refers to <https://rancher.com/docs/k3s/latest/en/installation/install-options/#registration-options-for-the-k3s-server>

So the install command should like this.

```bash

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san <your node public ip address>" sh -
```

Then you can copy the contents from `/etc/rancher/k3s/k3s.yaml` and save it in your local machine. Modifying the server's IP address from `127.0.0.1` to the real address you want to access with.

Try to fetch the cluster's info and all went well this time.

```bash
❯ kubectl get node
NAME         STATUS   ROLES                  AGE   VERSION
wenhan-dev   Ready    control-plane,master   61s   v1.22.7+k3s1
```


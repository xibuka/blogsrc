---
title: Certified Kubernetes Administrator (CKA) learning note
date: 2018-08-29 11:40:56
tags:
- Kubernetes
- CKA
---

# Install

1. Install docker.io

```
apt install docker.io
```

If you install docker with other cgroup driver, you have to make sure that
docker and Kubernetes will use same cgroup driver.

```
cat << EOF >> /etc/docker/daemon.json
{
    "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
```

1. install apt key and source to system

```
root@kube-master:~# curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
OK
root@kube-master:~# cat <<EOF >> /etc/apt/sources.list.d/kubernetes.list
> deb http://apt.kubernetes.io/ kubernetes-xenial main
> EOF
```

Then install kubernetes packages

```
root@kube-master:~# apt update -y
root@kube-master:~# apt install -y kubelet kubeadm kubectl

```

1. setup and config with kubeadm

<!-- more -->

You must choose a CNI when you execute `kubeadm init`, in this post I choose
flunnel, so I have to add `--pod-network-cidr` options.

```
root@k8sm:~# kubeadm init --pod-network-cidr=10.244.0.0/16
```

after waiting for some while, you should see below message that shows the
install is complete

```
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

Follow the instruction, run below comand as a regular user

```
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

And you need to memo the command start with `kubeadm join`, you will need to
exeute this command on your kubernetes node to join to the cluster

In order for your pods to communicate with one another, you'll need to install
pod networking.  We are going to use Flannel for our Container Network Interface
(CNI) because it's easy to install and reliable.  Enter this command:

```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

Next run below command to make sure everything is coming up.

```
kubectl get pods --all-namespaces
```

If you see the coredns-xxxxxx pod is running, and your master node is Ready,
your cluster is ready to accept worker nodes.

```
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

1. setup other node and join to the cluster

For the rest worker nodes, you just need to install kubectl, kubeadm, kubelet
and docker refer above, then execute the `kubeadm join ...` command which was
mentioned before.
After a while, you should see all worker nodes are ready to use.

```
wshi@k8sm:~$ kubectl get node
NAME      STATUS    ROLES     AGE       VERSION
k8sm      Ready     master    44m       v1.11.2
k8sn1     Ready     <none>    11m       v1.11.2
k8sn2     Ready     <none>    11m       v1.11.2
```

# Run a Job

Applications that running inside a pod are called "jobs".

Most Kubernetes objects are created using yaml. Here is a sample yaml for a job which uses perl to calculate pi to 2000 digits and then stops.

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

Create this yaml file on your master node and call it "pi-job.yaml". Run the job with the command:

```bash
kubectl create -f pi-job.yaml
```

Get the detail information of this job with the command:

```
$ kubectl get pod
NAME                                               READY     STATUS      RESTARTS   AGE
...
pi-72c7r                                           0/1       Completed   0          3m

$ kubectl describe pod pi-72c7r
Name:           pi-72c7r
Namespace:      default
Node:           juju-cfb27c-2/10.188.44.225
Start Time:     Wed, 29 Aug 2018 02:45:34 +0000
Labels:         controller-uid=9a903f30-ab35-11e8-9b51-feb3e5f3b327
                job-name=pi
Annotations:    <none>
Status:         Succeeded
IP:             10.1.33.7
Controlled By:  Job/pi
Containers:
  pi:
    Container ID:  docker://0d48f71cc6a2825cf4113f237170e63b06e1e310eca2e950dc979b48f26fb41f
    Image:         perl
    Image ID:      docker-pullable://perl@sha256:a264b269d0ea9687ea1485e47a0f4039b2dab99fc9c6e3faf001b452b57d6087
    Port:          <none>
    Host Port:     <none>
    Command:
      perl
      -Mbignum=bpi
      -wle
      print bpi(2000)
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Wed, 29 Aug 2018 02:47:01 +0000
      Finished:     Wed, 29 Aug 2018 02:47:07 +0000
    Ready:          False
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-pkk4t (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             False 
  ContainersReady   False 
  PodScheduled      True 
Volumes:
  default-token-pkk4t:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-pkk4t
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type    Reason     Age   From                    Message
  ----    ------     ----  ----                    -------
  Normal  Scheduled  3m    default-scheduler       Successfully assigned default/pi-72c7r to juju-cfb27c-2
  Normal  Pulling    3m    kubelet, juju-cfb27c-2  pulling image "perl"
  Normal  Pulled     1m    kubelet, juju-cfb27c-2  Successfully pulled image "perl"
  Normal  Created    1m    kubelet, juju-cfb27c-2  Created container
  Normal  Started    1m    kubelet, juju-cfb27c-2  Started container
```

And view the log(STDOUT) with below command:

```bash
$ kubectl logs pi-72c7r
3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938446095505822317253594081284811174502841027019385211055596446229489549303819644288109756659334461284756482337867831652712019091456485669234603486104543266482133936072602491412737245870066063155881748815209209628292540917153643678925903600113305305488204665213841469519415116094330572703657595919530921861173819326117931051185480744623799627495673518857527248912279381830119491298336733624406566430860213949463952247371907021798609437027705392171762931767523846748184676694051320005681271452635608277857713427577896091736371787214684409012249534301465495853710507922796892589235420199561121290219608640344181598136297747713099605187072113499999983729780499510597317328160963185950244594553469083026425223082533446850352619311881710100031378387528865875332083814206171776691473035982534904287554687311595628638823537875937519577818577805321712268066130019278766111959092164201989380952572010654858632788659361533818279682303019520353018529689957736225994138912497217752834791315155748572424541506959508295331168617278558890750983817546374649393192550604009277016711390098488240128583616035637076601047101819429555961989467678374494482553797747268471040475346462080466842590694912933136770289891521047521620569660240580381501935112533824300355876402474964732639141992726042699227967823547816360093417216412199245863150302861829745557067498385054945885869269956909272107975093029553211653449872027559602364806654991198818347977535663698074265425278625518184175746728909777727938000816470600161452491921732172147723501414419735685481613611573525521334757418494684385233239073941433345477624168625189835694855620992192221842725502542568876717904946016534668049886272327917860857843838279679766814541009538837863609506800642251252051173929848960841284886269456042419652850222106611863067442786220391949450471237137869609563643719172874677646575739624138908658326459958133904780275898
```

Here is another example YAML file for job which use the image "busybox" and sleep for 10 seconds

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

# Deploy a Pod

Pods usually represent running applications in a Kubernetes cluster.  Here is an example of some yaml which defines a pod:

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

## run a Pod
```bash
kubectl create -f alpine.yaml
```

## delete a Pod

```bash
kubectl delete -f alpine.yaml
```

Or

```
kubectl delete pod alpine
```

```
kubectl delete pod/alpine
```

# Examine the current status

```
kubectl get nodes
kubectl describe node node-name
kubectl get pods --all-namespaces -o wide
```

Use `-n` will specify the namespace in use

```
kubectl get pods -n kube-system
```

# Deployment

A yaml file for an nginx deployment

```
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

## Create the deployment and pod

```
kubectl create -f nginx-deployment.yaml
```

Find the detail info 

```
kubectl describe deployment nginx-deployment
```

Check pod is running on which node

```
$ kubectl get pod nginx-deployment-7fc9b7bd96-c6wwh -o wide
NAME                                READY     STATUS    RESTARTS   AGE       IP          NODE            NOMINATED NODE
nginx-deployment-7fc9b7bd96-c6wwh   1/1       Running   0          21h       10.1.33.6   juju-cfb27c-2   <none>
```

## rollout image version

Change the image version to 1.8, you run below command 

```
kubectl set image deployment nginx-deployment nginx=nginx:1.8
```

Or, you can update the line in the yaml to 1.8 version of the image, and apply
the changes with 

```
kubectl apply -f nginx-deployment.yaml
```

Check the status of the rollout with below command 

```
kubectl rollout status deployment nginx-deployment
```

Undo the previous rollout

```
kubectl rollout undo deployment nginx-deployment
```

View the history 

```
kubectl rollout history deployment nginx-deployment
```

Go to a specific point in history

```
kubectl rollout history deployment nginx-deployment --revision=x
```

# Setting Container Environment Variables

Deploy a pod to print Environment Variables

```
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

After executed the pod, you can check Environment Viriables by log

```
$ kubectl logs env-dump
....
STUDENT_NAME=Your Name
SCHOOL=Linux Academy
KUBERNETES=is awesome
....
```

# Scaling pod

## command line

Use scale to deployment with --replicas=X

```
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

## yaml file

Update `replicas: x` part in yaml file, and apply the changes with 

```
kubectl apply -f nginx-deployment.yml 
```

# Replication Controllers, Replica Sets, and Deployments

Deployments replaced the older ReplicationController functionality, but it never
hurts to know where you came from.  Deployments are easier to work with, 
and here's a brief exercise to show you how.
A Replication Controller ensures that a specified number of pod replicas are running
at any one time. In other words, a Replication Controller makes sure that a pod or
a homogeneous set of pods is always up and available.

To maintain three copies of an nginx container

## Replication Controllers
```
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

## ReplicaSet

```
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

## Deployment

```
apiVersion: apps/v1beta2 # for versions before 1.8.0 use apps/v1beta1
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

# Label

Label node with colors

```
kubectl label node node1-name color=black
kubectl label node node2-name color=red
kubectl label node node3-name color=green
kubectl label node node4-name color=blue
```

Label all pod in default namespace by using `--all`

```
kubectl label pods -n default color=white --all
```

Get pod/node/etc with specific label

```
kubectl get pods -l color=white -n default
```

Get pod with multi labels

```
kubectl get pods -l color=white,app=nginx
```

# DaemonSet

Deploy nginx pod on all node with

```
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

Confirm that pod is running on each node

```
$ kubectl get pod -o wide
NAME                                               READY     STATUS             RESTARTS   AGE       IP              NODE            NOMINATED NODE
cthulu-kvbk9                                       1/1       Running            0          2m        10.1.33.8       juju-cfb27c-2   <none>
cthulu-t7hfc                                       1/1       Running            0          2m        10.1.45.13      juju-cfb27c-1   <none>
cthulu-x8hdf                                       1/1       Running            0          2m        10.1.31.9       juju-cfb27c-3   <none>
```

# Label a Node & Schedule a Pod
Label a Node to let you can schedule a pod on it.

```
kubectl label node juju-cfb27c-3 deploy=here
```

use `nodeSelector` in yaml file to let a pod being deployed on the specific
node

```
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

Confirm

```
$ kubectl get pod busybox -o wide
NAME      READY     STATUS    RESTARTS   AGE       IP           NODE            NOMINATED NODE
busybox   1/1       Running   0          10s       10.1.31.10   juju-cfb27c-3   <none>
```

# Specific Schedulers

Ordinarily, we don't need to specify the scheduler's name in the spec because everyone uses a 
single default one. Sometimes, however, developers need to have custom schedulers in charge of 
placing pods due to legacy or specialized hardware constraints.

Use `schedulerName` in yaml to specific a customer scheduler

```
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

# Logs

View the current logs of a pod

```
kubectl logs pod-name
```

View the current logs of a pod interactively

```
kubectl logs pod-name -f
```

Print last 10 lines of the log.

```
kubectl logs pod-name --tail=10
```

Log file in master/node machine can be found at `/var/log/containers` directory

# Node maintenance

Maintenance a node by preventing the scheduler from putting new pods on to it and 
evicting any existing pods. Ignore the DaemonSets -- those pods are only providing 
services to other local pods and will come back up when the node comes back up.

In this example I'm going to remove juju-cfb27c-2 from cluster.

```
root@juju-cfb27c-0:~# kubectl drain juju-cfb27c-2 --ignore-daemonsets
node/juju-cfb27c-2 cordoned
WARNING: Ignoring DaemonSet-managed pods: cthulu-kvbk9, nginx-ingress-kubernetes-worker-controller-t6qh9
```

juju-cfb27c-2 is marked as "SchedulingDisabled"

```
# kubectl get node
NAME            STATUS                     ROLES     AGE       VERSION
juju-cfb27c-1   Ready                      <none>    4d        v1.11.2
juju-cfb27c-2   Ready,SchedulingDisabled   <none>    4d        v1.11.2
juju-cfb27c-3   Ready                      <none>    4d        v1.11.2
```

Now -2 node can be shutdown and do maintenance work, no pod will be schedule on
it. If you create some new pods, they will only placed on juju-cfb27c-1 and -3.

Next, when -2 node is ready to use, you can get it back with 

```
# kubectl uncordon juju-cfb27c-2 
node/juju-cfb27c-2 uncordoned
# kubectl get node
NAME            STATUS    ROLES     AGE       VERSION
juju-cfb27c-1   Ready     <none>    4d        v1.11.2
juju-cfb27c-2   Ready     <none>    4d        v1.11.2
juju-cfb27c-3   Ready     <none>    4d        v1.11.2

```

# Upgrading Kubernetes Components

Confirm the current version with

```
kubectl get nodes
```

1. Upgrade kubeadm on the master node

```
sudo apt upgrade kubeadm
```

And confirm the version of kubeadm with

```
kubeadm version
```

1. check the upgrade plan

```
sudo kubeadm upgrade plan
```

1. apply the upgrade plan

```
sudo kubeadm upgrade apply v1.x.x
```

1. upgrade kubelet

Before upgrade kubelet, first you need to drain the node which you want to
upgrade

```
kubectl drain NODENAME --ignore-daemonsets
```

Then, update kubelet manaully with 

```
sudo apt update
sudo apt upgrade kubelet
```

Don't forget to make your node avaliable after the upgrade.

```
kubectl uncordon NODENAME
```

# Network

## Inbound Node Port Requirements
- Master Nodes
  - TCP 6443         --  Kubernetes API Server
  - TCP 2379-2380    --  etcd server client API
  - TCP 10250        --  Kubelet API
  - TCP 10251        --  Kube-scheduler
  - TCP 10252        --  kube-controller-manager
  - TCP 10255        --  Read-only Kubelet API
- Worker Nodes
  - TCP 10250        --  Kubelet API
  - TCP 10255        --  Read-only Kubelet API
  - TCP 30000-32767  -- Node Port Services

## export pod to the internet

```
# kubectl expost deployment NAME --type="NodePort" --port XX
```

## Deploying a Load Balancer

```
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

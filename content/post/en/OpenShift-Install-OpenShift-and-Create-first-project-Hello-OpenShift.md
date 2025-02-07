---
title: '[OpenShift]Install OpenShift and Create first project Hello-OpenShift'
date: 2017-06-26 13:40:40
tags:
- OpenShift
- Linux
---

# Install Linux OS and confirm network setting.
You need to create a Linux OS machine to install OpenShift. The minimum
requirement is 

| CPU | Memory | hard disk | Network |
| --- | ------ | --------- | ------- |
| x86_64 1 core | 2 GB | 20 GB | IPv4|

First you need to install CentOS 7.3, by select minimum setup. After you finish
the installation, check your IP address to make sure you have available IP to
use. The following example shows the IP address at eth0 is "192.168.122.45"

<!-- more -->

```bash
[root@openshift ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 52:54:00:13:fc:b5 brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.45/24 brd 192.168.122.255 scope global dynamic eth0
       valid_lft 3251sec preferred_lft 3251sec
    inet6 fe80::a96e:889:48df:66a3/64 scope link 
       valid_lft forever preferred_lft forever
```

OpenShift need a hostname to provide the service. Use "hostnamectl set-hostname" 
to set a hostname. And use "hostname" to confirm your setting. The following
example show the hostname is "openshift.example.com"

```bash
[root@openshift ~]# hostnamectl set-hostname openshift.example.com
[root@openshift ~]# hostname
openshift.example.com
```

# Install docker

Openshift use docker as a container engine. Install docker by following
command.

```bash
[root@openshift ~]# yum install -y docker
```

After the installation is done, start the docker service and enable it.

```bash
[root@openshift ~]# systemctl start docker
[root@openshift ~]# systemctl enable docker
```

Test under command to check if docker can fetch data from internet. The
following example show how to create a "hello-openshift" container. This
little app was a go program and will listen 8080 and 8888 port.
(Run command for the first time will take some time because no image is existed
locally, docker need to pull it from the internet.)

```bash
[root@openshift ~]# docker run -it openshift/hello-openshift
Unable to find image 'openshift/hello-openshift:latest' locally
Trying to pull repository registry.access.redhat.com/openshift/hello-openshift ...
Trying to pull repository docker.io/openshift/hello-openshift ...
latest: Pulling from docker.io/openshift/hello-openshift

a3ed95caeb02: Pull complete
318ec9b73ccb: Pull complete
Digest: sha256:3fc5706d2bc0b4d804fd9a9b9f2456c811b525a222caf906b008d0a3e5aba212
serving on 8888
serving on 8080
```

After the test, push "Ctrl+c" to stop this image.

# Install OpenShift

There are several methods to install OpenShift. For better understand we will 
download the binaries of OpenShift server and deploy it manually.
You can find the download link at [Download OpenShift Origin](https://www.openshift.org/download.html). For now the latest version is [v1.5.1-7b451fc-linux-64bit.tar.gz](https://github.com/openshift/origin/releases/download/v1.5.1/openshift-origin-server-v1.5.1-7b451fc-linux-64bit.tar.gz). 

Download the file and untar it to /opt/

```bash
[root@openshift ~]# wget https://github.com/openshift/origin/releases/download/v1.5.1/openshift-origin-server-v1.5.1-7b451fc-linux-64bit.tar.gz
<snip>
[root@openshift ~]# cd /opt/
[root@openshift opt]# ls
[root@openshift opt]# tar xf ~/openshift-origin-server-v1.5.1-7b451fc-linux-64bit.tar.gz
<snip>
[root@openshift opt]# ln -s openshift-origin-server-v1.5.1-7b451fc-linux-64bit/ openshift
```

Add Openshift path to $PATH by add following text to the end of /etc/profile.
```
PATH=$PATH:/opt/openshift
```

Run source command to make the configuration enable,
```bash
[root@openshift ~]# source /etc/profile
```

After this we can check if the shell can find the command of openshift. Try
following command to check the version. From the output we can see the version
of Openshift is 1.5.1, Kubernetes is 1.5.2, and etcd is 3.1.0.

```bash
[root@openshift ~]# openshift version
openshift v1.5.1+7b451fc
kubernetes v1.5.2+43a9be4
etcd 3.1.0
```

# Start OpenShift
Just type "openshift start" to start openshift. There will be a lot of logs
output in the terminal. OpenShift will started when the logs output is stopped.

```bash
[root@openshift ~]# openshift start
<snip>
```

# Access OpenShift

## Open web control UI and login

Type "https://<OpenShift Hostname>:8443" to access the web control. Ignore the 
warning message of security and you will see the login page. Input username 
and password by "dev" to login.

![openshift login](/img/openshift-install/login.png)

## Create a new project

Click "New Project"
![create pods](/img/openshift-install/createpods1.png)

For the first test project, input the Name, Display Name and Description and click "Create".
![create pods](/img/openshift-install/createpods2.png)

At the next screen, click "Deploy Image" and select "Image Name". Input the
image name as "openshift/hello-openshift" and click the "find" icon at right to
find images.
![create pods](/img/openshift-install/createpods3.png)

After a while(depends on your network speed), the image will be downloaded,
click "Create" at the end of the page to create a pod.
![create pods](/img/openshift-install/createpods4.png)

OpenShift will start to deploy the pod, at first you will see a gray circle with a
number "1" in it. When the deployment is done, the circle will turn to blue,
it mean the pod is ready to use. 
![create pods](/img/openshift-install/createpods5.png)
![create pods](/img/openshift-install/createpods6.png)

Click the circle to see the detail information of your pods. You can find an "IP"
is attached to the pod. Following example shows the IP address of the pod is "172.17.0.3".
![create pods](/img/openshift-install/createpods7.png)

Back to the OpenShift server and run under command to check the hello-openshift container. 
The hello-openshift service will return a string "Hello OpenShift!" to each
request from the 8080 or 8888 port.

```bash
[root@openshift ~]# curl 172.17.0.3:8080
Hello OpenShift!
```

Above is a simple test of how to install Openshift and create a project/pod.
The IP will not be accessible outside the OpenShift server because it's only a
local IP address. To deploy a real useful pod and provide it, you need to do
more settings. I will update it in the further. #TODO


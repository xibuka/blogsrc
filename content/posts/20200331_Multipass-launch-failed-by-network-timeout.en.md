---
title: "Multipass Launch Failed by Network Timeout"
date: 2020-03-31T10:04:31+09:00
draft: false
tags:
- Ubuntu
---

Multipass is a very useful tools to create Ubuntu VM instance. It will provides
a CLI to launch and manage the Linux instances. The downloading of a cloud
image is also automatically, and a VM can be up and running within minutes.

[https://multipass.run/](https://multipass.run/)

But in my case, I tried multipass 1.1.0 to quick launch an instance, but it
failed with a `Network timeout` error.

```bash
$ multipass version
 multipass  1.1.0
 multipassd 1.1.0

$ multipass launch
launch failed: failed to download from 'http://cloud-images.ubuntu.com/releases/server/releases/bionic/release-20200317/ubuntu-18.04-server-cloudimg-amd64.img': Network timeout
```

I checked this link with `wget` and has no issue, so I assumpt the download
time of the image may too long to some timeout value in multipass.
Can we download it manually and start the instance by it? Sure we can.
You can download the images and pass the image path as a parameter.

```bash
$ multipass launch file:///home/wshi/Downloads/ubuntu-18.04-server-cloudimg-amd64.img
Launched: lucrative-eelpout 
```

One more thing about the download time in Japan. Using
`http://cloud-images.ubuntu.com` seems slow to me. So I switched to the mirror
of Toyama Univ. `http://ubuntutym2.u-toyama.ac.jp/cloud-images/releases/`.
It's 10 times faster than the origin one, hope this can help you.

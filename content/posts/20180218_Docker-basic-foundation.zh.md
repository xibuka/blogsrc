---
title: Docker基础入门
date: 2018-02-18 16:35:32
tags:
- Docker
---
以 CentOS 7、Docker 1.12.6 为基础说明。

## 安装 Docker

在 Linux 系统上安装 Docker 的前置条件：

- Docker 只能安装在 64 位操作系统上。
- 建议内核版本高于 3.10。
- 需要启用 cgroup 和 namespace。

现在在 CentOS 或 Fedora 上安装 Docker 更加简单，可以用如下 `yum` 命令搜索：

```bash
$ yum search docker | grep ^docker
docker-client.x86_64 : Client side files for Docker
docker-client-latest.x86_64 : Client side files for Docker
docker-common.x86_64 : Common files for docker and docker-latest
docker-compose.noarch : Multi-container orchestration for Docker
docker-distribution.x86_64 : Docker toolset to pack, ship, store, and deliver
docker-latest-logrotate.x86_64 : cron job to run logrotate on Docker containers
docker-latest-v1.10-migrator.x86_64 : Calculates SHA256 checksums for docker
docker-logrotate.x86_64 : cron job to run logrotate on Docker containers
docker-lvm-plugin.x86_64 : Docker volume driver for lvm volumes
docker-python.x86_64 : An API client for docker written in Python
docker-registry.x86_64 : Registry server for Docker
docker-v1.10-migrator.x86_64 : Calculates SHA256 checksums for docker layer
docker.x86_64 : Automates deployment of containerized applications
docker-devel.x86_64 : A golang registry for global request variables (source
docker-forward-journald.x86_64 : Forward stdin to journald
docker-latest.x86_64 : Automates deployment of containerized applications
docker-novolume-plugin.x86_64 : Block container starts with local volumes
docker-unit-test.x86_64 : Automates deployment of containerized applications -
```

运行 `yum -y install docker` 安装 Docker。

```bash
$ yum -y install docker

...snip...

Installed:
  docker.x86_64 2:1.12.6-71.git3e8e77d.el7.centos.1                                                                                                                      

Complete!

```

安装完成后，启动 docker 服务，并用 `docker version` 检查安装情况。

```bash
$ systemctl start docker

$ docker version
Client:
 Version:         1.12.6
 API version:     1.24
 Package version: docker-1.12.6-71.git3e8e77d.el7.centos.1.x86_64
 Go version:      go1.8.3
 Git commit:      3e8e77d/1.12.6
 Built:           Tue Jan 30 09:17:00 2018
 OS/Arch:         linux/amd64

Server:
 Version:         1.12.6
 API version:     1.24
 Package version: docker-1.12.6-71.git3e8e77d.el7.centos.1.x86_64
 Go version:      go1.8.3
 Git commit:      3e8e77d/1.12.6
 Built:           Tue Jan 30 09:17:00 2018
 OS/Arch:         linux/amd64
```

## Docker 基本命令

这里介绍一些 Docker 的基本命令，更多细节请参考 [Docker Documentation](https://docs.docker.com/engine/reference/commandline/docker/)。

Docker 命令用于与 docker 守护进程通信。
docker 守护进程会监听并执行 docker 命令。运行 `docker` 或 `docker --help` 可以查看命令列表。

```bash
$ docker --help
...
Commands:
    attach    Attach to a running container
    build     Build an image from a Dockerfile
    commit    Create a new image from a container's changes
    ...
    version   Show the Docker version information
    volume    Manage Docker volumes
    wait      Block until a container stops, then print its exit code

Run 'docker COMMAND --help' for more information on a command.
```

运行 docker 命令需要 root 权限。

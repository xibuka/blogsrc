---
title: Docker基礎入門
date: 2018-02-18 16:35:32
tags:
- Docker
---
CentOS 7、Docker 1.12.6 をベースに解説します。

## Dockerのインストール

Linux OSにDockerをインストールするための事前要件：

- Dockerは64ビットOSでのみインストール可能です。
- カーネルバージョンは3.10以上が推奨されます。
- cgroupとnamespaceを有効にする必要があります。

現在、CentOSやFedoraではDockerのインストールが簡単になっており、
以下のように`yum`コマンドで検索できます：

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

`yum -y install docker` を実行してDockerをインストールします。

```bash
$ yum -y install docker

...snip...

Installed:
  docker.x86_64 2:1.12.6-71.git3e8e77d.el7.centos.1                                                                                                                      

Complete!

```

インストール後、dockerサービスを起動し、`docker version`でセットアップを確認します。

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

## Dockerの基本コマンド

ここではDockerの基本的なコマンドを紹介します。詳細は [Docker Documentation](https://docs.docker.com/engine/reference/commandline/docker/) を参照してください。

Dockerコマンドはdockerデーモンと通信するためのものです。
dockerデーモンはコマンドを受け取り実行します。`docker` または `docker --help` を実行するとコマンド一覧が表示されます。

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

Dockerコマンドの実行にはroot権限が必要です。

---
title: "Hello World！运行第一次代码扫描"
description: "通过分步截图介绍如何在 SonarQube 中创建项目并运行第一次代码扫描。"
date: 2025-12-02T23:49:19+09:00
draft: false
tags:
- SonarQube
- SonarScanner
- codesmell
- SAST
- CodeScanning
---

在将静态分析集成到 CI/CD 之前，可以先在本地试运行。本文根据 [Qiita 原文](https://qiita.com/xibuka/items/42a93ae2b401d1296052)，使用 Docker 启动 SonarQube Server，并通过 SonarScanner CLI 分析示例代码。

## 目标与准备

扫描源代码，并在 SonarQube 页面查看 Bug 和代码异味。准备 Docker Desktop 或 Docker Engine，以及以下 Python 文件：

```python
def hello():
    print("Hello World")
    x = 10  # unused variable

hello()
```

## 启动 SonarQube Server

```bash
docker run -d --name sonarqube -p 9000:9000 sonarqube:community
```

在浏览器打开 `http://localhost:9000`，使用初始用户名和密码 `admin` / `admin` 登录。首次登录后需要修改密码。

![SonarQube 初始登录页面](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/b600c4f3-bb06-4146-869d-9efe61038501.png)

## 准备项目、Token 和 URL

在页面中选择 [Create a local project]，创建显示名称为 `hello-world` 的项目。然后进入 My Account > Security 创建 Token，例如命名为 `scanner-cli`。关闭页面前请复制 Token。

![开始创建本地项目](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/a13aa65e-7eb3-4ac3-9412-cb053cc0f342.png)

![输入项目显示名称](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/1e1d234a-d9ae-4b4f-a4fe-720da301952c.png)

![确认项目设置](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/f08b92e0-bdf9-45a3-b58f-eec9e5879da9.png)

![生成 SonarQube Token](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/e89254ee-85df-46d3-a0fb-bc15614a2c2b.png)

Docker Desktop（Windows/Mac）从容器访问主机时使用 `http://host.docker.internal:9000`。Linux 环境可使用 `http://localhost:9000` 或容器 IP。

## 使用 SonarScanner CLI 扫描

进入 `main.py` 所在目录，将 Token 替换后运行：

```bash
docker run --rm \
  -e SONAR_HOST_URL="http://host.docker.internal:9000" \
  -e SONAR_TOKEN="<your-token>" \
  -v "$(pwd):/usr/src" \
  sonarsource/sonar-scanner-cli \
  -Dsonar.projectKey=hello-world
```

`--rm` 会在扫描完成后删除 Scanner 容器；`-v` 将当前源码目录挂载到容器内的 `/usr/src`。日志最后出现 `EXECUTION SUCCESS` 表示分析成功。

## 查看分析结果

刷新 SonarQube 项目页面 `http://localhost:9000/dashboard?id=hello-world`，然后打开 Issues。可以看到未使用变量 `x` 等问题，并查看问题位置和修复建议。

![SonarQube 检测到的 Issue](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/540a69c4-510c-484a-a6e6-12eb21bd1705.png)

![Issue 位置和修复建议](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/3656744c-a775-4a18-aa09-78dc4ba3f6b5.png)

## 总结

使用 Docker，无需复杂配置文件即可完成第一次静态分析。集成到 CI 时，基本上也是在 CI 作业中执行同一条 Scanner 命令。

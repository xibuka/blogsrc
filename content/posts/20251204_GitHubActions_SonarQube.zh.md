---
title: "集成 GitHub Actions，自动分析 Pull Request"
date: 2025-12-04T23:49:19+09:00
draft: false
tags:
- GitHub
- SonarQube
- CICD
---

本文根据 [Qiita 原文](https://qiita.com/xibuka/items/14f127a56bc24924c83b)，介绍如何在创建或更新 Pull Request（PR）时，通过 GitHub Actions 自动运行 SonarQube Server 分析。这样可以在代码评审前发现 Bug 和代码异味。

## 准备 SonarQube

在 SonarQube 中为目标仓库创建项目并记录 Project Key。然后进入 My Account > Security 生成 Analysis Token，并复制保存。

## 设置 GitHub Secrets

在仓库的 Settings > Secrets and variables > Actions 中添加以下 Repository Secrets：

| 名称 | 值 |
| --- | --- |
| `SONAR_TOKEN` | 在 SonarQube 创建的 Token |
| `SONAR_HOST_URL` | SonarQube Server URL |

GitHub Actions 运行在云端，无法访问本机 `localhost` 上的 SonarQube。请提供可从互联网访问的服务器地址；试用时也可以使用 ngrok 等隧道工具。

## 创建工作流

添加 `.github/workflows/sonar-analysis.yml`：

```yaml
name: SonarQube Analysis

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  build:
    name: Build and Analyze
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: SonarQube Scan
        uses: sonarsource/sonarqube-scan-action@v2.0.1
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
        with:
          args: >
            -Dsonar.projectKey=my-project
```

将 `my-project` 替换为自己的 Project Key。`fetch-depth: 0` 会获取完整 Git 历史，以便 SonarQube 分析 SCM 信息。

## 在 PR 中确认结果

推送分支修改并创建 PR 后，可在 Actions 的 Checks 页面查看分析作业。运行成功后，在 SonarQube 项目页面查看 PR 分析结果，包括 Bugs、Vulnerabilities、Code Smells 及对应源代码行。

## 总结

在 PR 创建或更新时自动运行 SonarQube 分析，可以尽早发现质量问题。还可以配合 Quality Gate，阻止未达到质量标准的 PR 合并。

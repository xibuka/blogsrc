---
title: "体验 SonarQube CLI：让静态分析更简单、更智能"
description: "介绍 SonarQube CLI 的安装与基本用法，演示如何在本地或 CI 中分析项目，让静态代码分析更简单。"
date: 2026-05-05T23:49:19+09:00
draft: false
tags:
- SonarQube
---

本文根据 [Qiita 原文](https://qiita.com/xibuka/items/a74d6cc7705c28258186)，整理 `sonar` 命令提供的主要功能。传统的 `sonar-scanner` 主要面向 CI/CD 分析，而新的 CLI 更关注本地开发者和 AI Agent 的使用场景。

## 身份验证

使用 `sonar auth login` 通过浏览器登录。连接 SonarQube Server 或 SonarQube Cloud US 时，可以用 `-s` 指定服务器地址。

```bash
sonar auth login
sonar auth login -s https://my-sonarqube.io
sonar auth status
```

登录凭证会保存在操作系统的密钥链等位置。运行 `sonar auth status` 可查看连接地址和认证状态。

## 查看项目与 Issue

```bash
sonar list projects
sonar list issues -p <project-key>
```

命令输出为 JSON，可通过 `jq` 提取需要的字段。Issue 数量很多时，可以使用 `head` 等命令限制输出。

## 分析本地文件

```bash
sonar analyze secrets app.ts
sonar analyze sqaa --file app.ts -p <project-key>
sonar verify --file app.ts -p <project-key>
```

`secrets` 使用本地 Analyzer 检查文件中的秘密信息。`sqaa` 使用 SonarQube Cloud 的 Agentic Analysis 分析指定文件并返回 Issue。还可以指定项目和分支，为分析提供正确的上下文。

## 使用 Git Hook 检查密钥

```bash
sonar integrate git
```

按照交互提示选择仓库以及 `pre-commit` 或 `pre-push`。安装后，Git Hook 会在提交或推送前扫描文件；发现密钥时可以阻止操作。请确保当前 Shell 的 PATH 中包含 `sonar`。

通过 CLI，可以在同一套 `sonar` 命令中完成认证、查看 Issue、本地分析和 Git Hook 集成。

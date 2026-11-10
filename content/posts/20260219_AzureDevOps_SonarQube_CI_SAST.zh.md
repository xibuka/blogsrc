---
title: "使用 Azure DevOps 和 SonarQube 实现 CI SAST 扫描"
date: 2026-02-19T23:49:19+09:00
draft: false
tags:
- SonarQube
- AzureDevOps
- codequality
- SAST
---

本文根据 [Qiita 原文](https://qiita.com/xibuka/items/6a4e0decb076f6acea83)，整理如何使用 SonarQube Server（SQS）自动分析 Azure DevOps（ADO）的 Pull Request。目标是在创建 PR 时执行 SAST，并将分析结果反馈到 PR。

## 连接 SonarQube 与 Azure DevOps

集成需要 ADO URL 和 Personal Access Token（PAT）。在 SonarQube 中基于 ADO 仓库创建项目，并在 SonarQube 侧注册 ADO 集成。

![SonarQube 与 Azure DevOps 集成设置](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/abb21d8d-eb5f-4b05-8da9-2818e00783c7.png)

![Azure DevOps PAT 设置](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/ffaafaf9-0bb4-4573-928b-a163950dc6bd.png)

![基于 ADO 仓库创建 SonarQube 项目](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/26a4109b-9518-458a-a5fe-9d69d8b35a96.png)

## 配置 Azure DevOps

在 ADO 中安装 SonarQube 应用，并创建连接到 SonarQube 的 Service Connection。随后使用该连接配置 Pipeline。原文的示例会分析 PR 和 `master` 分支：

![在 Azure DevOps 中添加 SonarQube 应用](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/845c09c0-994c-4e1f-920e-97e86c196ec3.png)

![SonarQube 应用设置](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/8aabff38-9696-4294-8566-a9f052ee8d72.png)

![创建 Service Connection](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/786ff5f9-7c00-41e4-917a-3876179da4f2.png)

![配置 Service Connection](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/dd107e35-0ef5-4bac-b30c-0ca66f7836c3.png)

![创建 Azure DevOps Pipeline](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/b386c363-fd24-468a-934c-eb2f797dd229.png)

```yaml
trigger:
- master

pr:
- '*'

pool:
  vmImage: ubuntu-latest

steps:
- checkout: self
  fetchDepth: 0
- task: SonarQubePrepare@8
  inputs:
    SonarQube: 'SonarQubeNgrok'
    scannerMode: 'cli'
    configMode: 'manual'
    cliProjectKey: 'wenhan-Sonar_xxxxx'
    cliSources: '.'
- task: SonarQubeAnalyze@8
  inputs:
    jdkversion: 'JAVA_HOME_21_X64'
- task: SonarQubePublish@8
  inputs:
    pollingTimeoutSec: '300'
```

![SonarQube Pipeline 配置](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/f2a07da3-00b1-449f-b3bb-742df9b29c16.png)

将 `SonarQube` 设置为已创建的 Service Connection 名称，并把 `cliProjectKey` 替换为 SQS 项目键。

## 配置 Branch Policy 并验证 PR

在 ADO 的 Branch Policy 中将目标 Pipeline 设置为必需检查。修改示例代码并创建 PR，确认 Pipeline 的分析结果已发送到 SonarQube，并且 PR 中可以看到 Quality Gate 结果和 Issue 详情。

![将 Pipeline 添加到 Branch Policy](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/06aef763-c8b3-4793-975f-e7f0fdaff638.png)

![Branch Policy 配置结果](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/beef3cb5-77e9-4b05-af17-0b2d5f7d763b.png)

![Pipeline 分析结果](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/9081656e-e8e8-4f58-b025-d8f51bdbee04.png)

![PR 中显示的 Quality Gate 和 Issue](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/1a5b0844-1fae-46f3-9600-4b7a684697a3.png)

![PR 中的分析反馈](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/61372723-70ee-4ced-9ee9-03bff4c04c94.png)

完成配置后，每个 PR 都可以自动运行分析并展示结果。

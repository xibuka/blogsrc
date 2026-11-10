---
title: "Azure DevOpsとSonarQubeで実現するCI SASTスキャン"
description: "Azure DevOps PipelineとSonarQubeを連携し、CIでSAST解析を実行してPull RequestにQuality GateとIssueを表示する手順を解説します。"
date: 2026-02-19T23:49:19+09:00
draft: false
tags:
- SonarQube
- AzureDevOps
- codequality
- SAST
---

[Qiitaの記事](https://qiita.com/xibuka/items/6a4e0decb076f6acea83)をもとに、Azure DevOps（ADO）のPull RequestをSonarQube Server（SQS）で自動解析する流れをまとめます。目的は、PR作成時にSASTを実行し、解析結果をPRへ反映することです。

## SonarQubeとAzure DevOpsの接続

連携にはADOのURLとPersonal Access Token（PAT）が必要です。SonarQubeでADOのリポジトリをもとにプロジェクトを作成し、SonarQube側でADO連携を登録します。

![SonarQubeとAzure DevOpsの連携設定](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/abb21d8d-eb5f-4b05-8da9-2818e00783c7.png)

![Azure DevOpsのPAT設定](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/ffaafaf9-0bb4-4573-928b-a163950dc6bd.png)

![ADOリポジトリからSonarQubeプロジェクトを作成](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/26a4109b-9518-458a-a5fe-9d69d8b35a96.png)

## Azure DevOpsの設定

ADOにSonarQubeアプリをインストールし、SonarQubeへのService Connectionを作成します。その接続を使ってPipelineを設定します。記事の例では、PRと `master` ブランチを対象にし、SonarQubeタスクで解析します。

![Azure DevOpsにSonarQubeアプリを追加](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/845c09c0-994c-4e1f-920e-97e86c196ec3.png)

![SonarQubeアプリの設定](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/8aabff38-9696-4294-8566-a9f052ee8d72.png)

![Service Connectionの作成](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/786ff5f9-7c00-41e4-917a-3876179da4f2.png)

![Service Connectionの設定](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/dd107e35-0ef5-4bac-b30c-0ca66f7836c3.png)

![Azure DevOps Pipelineの作成](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/b386c363-fd24-468a-934c-eb2f797dd229.png)

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

![SonarQube Pipelineの設定](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/f2a07da3-00b1-449f-b3bb-742df9b29c16.png)

`SonarQube` には作成したService Connection名、`cliProjectKey` にはSQSプロジェクトのキーを指定します。実際の接続名とプロジェクトキーに置き換えてください。

## Branch PolicyとPRの確認

ADOのBranch Policyで対象Pipelineを必須チェックとして設定します。サンプルコードを変更してPRを作成し、Pipelineの解析結果がSonarQubeに送信されること、Quality GateとIssueの詳細がPRに表示されることを確認します。

![Branch PolicyにPipelineを追加](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/06aef763-c8b3-4793-975f-e7f0fdaff638.png)

![Branch Policyの設定結果](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/beef3cb5-77e9-4b05-af17-0b2d5f7d763b.png)

![Pipelineによる解析結果](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/9081656e-e8e8-4f58-b025-d8f51bdbee04.png)

![PRに表示されたQuality GateとIssue](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/1a5b0844-1fae-46f3-9600-4b7a684697a3.png)

![PR上の解析フィードバック](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/61372723-70ee-4ced-9ee9-03bff4c04c94.png)

これにより、PRごとの自動解析と結果確認を行えるようになります。

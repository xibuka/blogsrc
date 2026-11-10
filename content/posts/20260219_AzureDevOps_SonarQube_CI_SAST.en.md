---
title: "CI SAST Scanning with Azure DevOps and SonarQube"
description: "Set up SonarQube SAST analysis in an Azure DevOps Pipeline and show Quality Gate results and issues directly on pull requests."
date: 2026-02-19T23:49:19+09:00
draft: false
tags:
- SonarQube
- AzureDevOps
- codequality
- SAST
---

Based on the [Qiita article](https://qiita.com/xibuka/items/6a4e0decb076f6acea83), this post outlines how to automatically analyze Azure DevOps (ADO) pull requests with SonarQube Server (SQS). The goal is to run SAST when a PR is created and surface the analysis results in the PR.

## Connect SonarQube and Azure DevOps

The integration requires the ADO URL and a Personal Access Token (PAT). Create a SonarQube project from the ADO repository, then register the ADO integration in SonarQube.

![SonarQube and Azure DevOps integration settings](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/abb21d8d-eb5f-4b05-8da9-2818e00783c7.png)

![Azure DevOps PAT settings](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/ffaafaf9-0bb4-4573-928b-a163950dc6bd.png)

![Create a SonarQube project from an ADO repository](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/26a4109b-9518-458a-a5fe-9d69d8b35a96.png)

## Configure Azure DevOps

Install the SonarQube app in ADO and create a Service Connection to SonarQube. Use that connection in a Pipeline. The example below analyzes PRs and the `master` branch:

![Add the SonarQube app to Azure DevOps](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/845c09c0-994c-4e1f-920e-97e86c196ec3.png)

![Configure the SonarQube app](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/8aabff38-9696-4294-8566-a9f052ee8d72.png)

![Create a Service Connection](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/786ff5f9-7c00-41e4-917a-3876179da4f2.png)

![Configure the Service Connection](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/dd107e35-0ef5-4bac-b30c-0ca66f7836c3.png)

![Create the Azure DevOps Pipeline](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/b386c363-fd24-468a-934c-eb2f797dd229.png)

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

![SonarQube Pipeline configuration](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/f2a07da3-00b1-449f-b3bb-742df9b29c16.png)

Set `SonarQube` to the name of your Service Connection and replace `cliProjectKey` with the SQS project key.

## Add a Branch Policy and verify a PR

Set the target Pipeline as a required check in the ADO Branch Policy. Modify sample code and create a PR. Confirm that the Pipeline sends its analysis to SonarQube and that the PR displays the Quality Gate result and issue details.

![Add the Pipeline to the Branch Policy](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/06aef763-c8b3-4793-975f-e7f0fdaff638.png)

![Branch Policy configuration](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/beef3cb5-77e9-4b05-af17-0b2d5f7d763b.png)

![Pipeline analysis result](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/9081656e-e8e8-4f58-b025-d8f51bdbee04.png)

![Quality Gate and issues shown on the PR](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/1a5b0844-1fae-46f3-9600-4b7a684697a3.png)

![Analysis feedback on the PR](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/61372723-70ee-4ced-9ee9-03bff4c04c94.png)

This setup runs analysis automatically for each PR and makes the results available during review.

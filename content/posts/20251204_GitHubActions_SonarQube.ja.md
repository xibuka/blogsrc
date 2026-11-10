---
title: "GitHub Actionsと連携してPRを自動解析する"
description: "GitHub ActionsからSonarQube解析を実行し、Pull Requestごとにコード品質を自動チェックするワークフローを構築します。"
date: 2025-12-04T23:49:19+09:00
draft: false
tags:
- GitHub
- SonarQube
- CICD
---

[Qiitaの記事](https://qiita.com/xibuka/items/14f127a56bc24924c83b)をもとに、GitHub ActionsでPull Request（PR）を作成・更新したときにSonarQube Serverの解析を実行する方法を紹介します。レビュー前にバグやCode Smellを検出できます。

## SonarQubeの準備

SonarQubeで対象リポジトリのプロジェクトを作成し、Project Keyを控えます。続いて My Account > Security でAnalysis Tokenを生成し、後で使うためにコピーします。

## GitHub Secretsの設定

リポジトリの Settings > Secrets and variables > Actions で次のRepository Secretsを追加します。

| Name | 値 |
| --- | --- |
| `SONAR_TOKEN` | SonarQubeで作成したトークン |
| `SONAR_HOST_URL` | SonarQube ServerのURL |

GitHub Actionsはクラウド上で動くため、`localhost` のSonarQubeには接続できません。インターネットから到達できるサーバーを指定するか、試験時はngrokなどのトンネルを利用します。

## ワークフローの作成

`.github/workflows/sonar-analysis.yml` を追加します。

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

`my-project` は自分のProject Keyに置き換えてください。`fetch-depth: 0` は全履歴を取得し、SCM情報を解析できるようにする設定です。

## PRで確認する

ブランチに変更をプッシュしてPRを作成すると、ActionsのChecksで解析ジョブの実行状況を確認できます。成功後、SonarQubeのプロジェクト画面でPRの解析結果を確認します。Bugs、Vulnerabilities、Code Smellsと、該当するソースコードの行が表示されます。

## まとめ

PR作成・更新時にSonarQube解析を自動実行することで、レビューの早い段階で品質問題を把握できます。Quality Gateを組み合わせれば、基準を満たさないPRのマージを防ぐ運用にも発展できます。

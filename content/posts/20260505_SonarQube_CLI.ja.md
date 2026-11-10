---
title: "SonarQube CLI を使ってみた。静的解析をよりシンプル＆スマートに"
date: 2026-05-05T23:49:19+09:00
draft: false
tags:
- SonarQube
---

[Qiitaの記事](https://qiita.com/xibuka/items/a74d6cc7705c28258186)をもとに、`sonar` コマンドで使える主な機能をまとめます。従来の `sonar-scanner` がCI/CDでの解析を中心にするのに対し、新しいCLIはローカル開発やAIエージェントとの連携を意識しています。

## 認証

`sonar auth login` でブラウザー認証を行います。SonarQube ServerやSonarQube Cloud USを使う場合は、サーバーを `-s` で指定します。

```bash
sonar auth login
sonar auth login -s https://my-sonarqube.io
sonar auth status
```

認証情報はOSのキーチェーンなどに保存されます。`sonar auth status` で接続先と認証状態を確認できます。

## プロジェクトとIssueの一覧

```bash
sonar list projects
sonar list issues -p <project-key>
```

JSONを `jq` に渡せば、必要なフィールドだけを抽出できます。Issueが多い場合は `head` などで出力を絞ります。

## ローカルファイルの解析

```bash
sonar analyze secrets app.ts
sonar analyze sqaa --file app.ts -p <project-key>
sonar verify --file app.ts -p <project-key>
```

`secrets` はローカルのAnalyzerで秘密情報を検出します。`sqaa` はSonarQube CloudのAgentic Analysisを使い、指定ファイルのIssueを返します。プロジェクトやブランチを指定して、解析対象の文脈を合わせられます。

## Gitフックによるシークレット検査

```bash
sonar integrate git
```

対話形式でリポジトリと `pre-commit` または `pre-push` を選びます。フックを導入すると、コミットやプッシュの前に対象ファイルを検査し、シークレットが見つかった場合は処理を止められます。利用するシェルで `sonar` にPATHが通っていることを確認してください。

CLIを使うと、認証、Issue確認、ローカル解析、Gitフックを一つの `sonar` コマンドから扱えます。

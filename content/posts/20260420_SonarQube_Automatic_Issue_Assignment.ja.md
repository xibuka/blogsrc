---
title: "SonarQubeの自動Issue割り当てで、コードの負債管理をスムーズにする"
description: "SonarQubeの自動Issue割り当てを設定し、コード変更者に課題を割り当てて修正責任を明確にする方法を紹介します。"
date: 2026-04-20T23:49:19+09:00
draft: false
tags:
- SonarQube
- 技術的負債
- コード品質
---

[Qiitaの記事](https://qiita.com/xibuka/items/d4bd739ab06e28bfa919)をもとに、SonarQubeのAutomatic Issue Assignmentを紹介します。コードスキャン後に大量のIssueが見つかると、誰に割り当てるかを決める作業が負担になります。この機能はSCM情報を使って、Issueを該当コードの開発者に自動で割り当てます。

## 自動割り当ての仕組み

解析時にGitなどのSCM情報を取得し、Issueが検出された行の最終更新者を特定します。SonarQube上のユーザーとSCMのコミッターをメールアドレスで照合し、一致したユーザーへIssueを割り当てます。

処理の流れは次の通りです。

1. 解析時に各行の最終更新者情報（`git blame` 相当）を取得する
2. Issueの位置から、その行を最後にコミットしたユーザーを特定する
3. SCM上のメールアドレスをSonarQubeユーザーにマッピングする
4. 対応するユーザーにIssueを割り当てる

## 動作確認

SonarQubeに、SCMで使うメールアドレスと一致するユーザーを登録します。記事ではGitHub連携を利用し、SonarQubeの3ユーザーに対応するアカウントからコードをコミットしています。

![SonarQubeのユーザー設定](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/caefca22-a964-4661-b12f-5801cca8c3e9.png)

各ユーザーに対応するGitHubアカウントから、それぞれコードをコミットします。

![GitHubからコードをコミット](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/14f8d156-98f7-4544-8604-9db21951b0f2.png)

コミット後に解析を実行すると、検出されたIssueが該当コードの最終コミッターに自動で割り当てられます。SCM連携が正しく設定され、ユーザーのメールアドレスが対応していることが前提です。

![Issueの自動割り当て結果](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/4c2fcc7e-cd4f-4275-ac1e-5efdc559a377.png)

## まとめ

SCM連携を設定すれば、Issueの担当者を手作業で決める負担を減らし、コードを変更した開発者へ改善作業をつなげられます。解析後にIssueが放置されがちなチームでは、自動割り当ての設定とユーザーのマッピングを確認してみてください。

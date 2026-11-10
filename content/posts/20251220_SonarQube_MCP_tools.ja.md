---
title: "SonarQube MCP Serverで利用可能なツール一覧"
date: 2025-12-20T23:49:19+09:00
draft: false
tags:
- SonarQube
- 静的解析
- MCP
- SCA
---

[Qiitaの記事](https://qiita.com/xibuka/items/6d18a1a04f4c1276f220)をもとに、SonarQube MCP Serverが公開するツールをカテゴリ別に整理します。MCPを介して、AIアシスタントがSonarQubeのデータや解析機能を利用できます。

## ツールのカテゴリ

| カテゴリ | 主なツール | 用途 |
| --- | --- | --- |
| コード解析 | `analyze_code_snippet`, `analyze_file_list`, `toggle_automatic_analysis` | スニペット・ファイルの解析、IDE自動解析の切替 |
| 依存関係リスク | `search_dependency_risks` | プロジェクトの依存関係リスクを検索 |
| Enterprise | `list_enterprises` | SonarQube Cloud Enterpriseの一覧 |
| Issue | `change_sonar_issue_status`, `search_sonar_issues_in_projects` | Issue検索と状態変更 |
| Projects / Portfolios | `search_my_sonarqube_projects`, `list_portfolios` | プロジェクト・ポートフォリオ検索 |
| Quality Gate | `get_project_quality_gate_status`, `list_quality_gates` | ゲート状態と定義の取得 |
| Metrics | `get_component_measures`, `search_metrics` | カバレッジ、複雑度などの取得 |
| Rules / Sources | `show_rule`, `list_rule_repositories`, `get_raw_source`, `get_scm_info` | ルール、ソース、SCM情報の取得 |
| System | `get_system_health`, `get_system_info`, `get_system_logs`, `get_system_status`, `ping_system` | サーバー状態やログの確認 |
| Webhooks | `create_webhook`, `list_webhooks` | Webhookの作成・一覧 |

`search_dependency_risks` はSonarQube Server 2025.4 Enterprise以上でAdvanced Securityを有効にした場合に利用できます。その他のツールにも、Server/Cloudや権限による条件があります。

## 活用例

これらのツールを組み合わせると、AIアシスタントからIssueの検索、Quality Gateの確認、メトリクスの取得、ルールやソースの参照を行えます。権限を確認したうえで、操作対象のプロジェクトやブランチを明示してください。

詳細な仕様は[SonarQube MCP Serverの公式ドキュメント](https://docs.sonarsource.com/sonarqube-server/)を参照してください。

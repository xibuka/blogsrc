---
title: "SonarQube × MCP完全ガイド：静的解析結果をAIコーディングで修正する"
date: 2025-12-14T23:49:19+09:00
draft: false
tags:
- SonarQube
- 静的解析
- MCP
- Gemini
- AIコーディング
---

AIによってコードを書く速度は上がりましたが、解析結果の確認や手作業での修正が新たな負担になります。[Qiitaの記事](https://qiita.com/xibuka/items/1377f143d9c32838a90c)をもとに、SonarQubeとMCPをつなぎ、AI AgentがIssueの取得から修正まで行う流れを紹介します。

## SonarQube MCP Serverとは

これまではSonarQubeの画面からIssueをコピーし、AIチャットに貼り付けて修正を依頼する必要がありました。MCPを使うと、AIクライアントがSonarQube APIからIssueを取得し、ローカルのソースコードを読み、修正案をファイルに反映できます。

## 構成と処理フロー

GeminiをAgentとして、ローカルのソースコード、SonarQube MCP Server、SonarQube Serverを連携させます。処理は次の4段階です。

![SonarQube MCPを使ったAIコード修正の構成図](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/757f6678-b58c-4e55-9c1a-4d7f55216959.png)

1. AI Agentがプロンプトに基づいてコードを生成する
2. SonarScannerで静的解析し、結果をSonarQube Serverに送信する
3. MCP Server経由で解析結果のIssueを取得する
4. AI Agentがコードの文脈を読み、Issueを修正する

必要なものはDocker、SonarScanner CLI、Gemini CLI（またはMCP対応クライアント）です。

## SonarQube ServerとMCPクライアントの準備

```bash
docker run -d --name sonarqube \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  -p 9000:9000 \
  sonarqube:community
```

`http://localhost:9000` にアクセスし、プロジェクト `mcp-demo` とUser Tokenを作成します。Gemini CLIを使う場合は `~/.gemini/settings.json` にMCP Serverを登録します。

```json
{
  "mcpServers": {
    "sonarqube": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "-e", "SONARQUBE_TOKEN", "-e", "SONARQUBE_URL", "mcp/sonarqube"],
      "env": {
        "SONARQUBE_TOKEN": "squ_xxxxxxxxx",
        "SONARQUBE_URL": "http://host.docker.internal:9000"
      }
    }
  }
}
```

トークンとURLは自分の環境に合わせて設定します。MCPクライアントから `get_system_health` を呼び出し、接続を確認します。MCP Server自体はローカルで動くDockerコンテナーです。

## 解析と修正のサイクル

まずAIにJavaScriptの数独ゲームを作らせ、`index.html`、`style.css`、`script.js` を生成します。次にSonarScannerで解析します。

```bash
sonar-scanner \
  -Dsonar.projectKey=mcp-demo \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=<your-token>
```

解析後、AIに「SonarQubeのmcp-demoのIssueを確認してください」と依頼します。MCPの `search_sonar_issues_in_projects` で11件のIssueを取得し、認知的複雑度、関数の配置、コントラスト、配列生成、数値変換などの指摘を確認しました。

続いてIssueに基づく修正を依頼すると、AI Agentは複雑な関数をリファクタリングし、コントラストや推奨APIの利用を修正しました。再スキャンを行い、オープンIssueがなくなったことを確認します。

## まとめ

この構成では「コード生成 → 解析 → Issue取得 → 修正」をAI Agentが繰り返します。MCP ServerはAIとSonarQube間の連携を担い、解析結果を手作業でコピーする工程を省けます。修正後には再解析し、結果を確認してください。

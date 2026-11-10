---
title: "SonarQube MCP Serverの機能一覧：静的コード解析"
date: 2025-12-16T23:49:19+09:00
draft: false
tags:
- SonarQube
- 静的解析
- MCP
- MCPサーバー
---

[Qiitaの記事](https://qiita.com/xibuka/items/08db95094091358d2c03)をもとに、SonarQube MCP Serverの静的コード解析機能を紹介します。MCPサーバー単体でコードを調べられるため、SonarScannerやIDEを準備せずに手軽なチェックを行えます。一方、高度なデータフロー解析や複雑な脆弱性検出は、通常のSonarQube解析が必要です。

## 主な機能

MCP Serverは静的解析のほか、Quality Gate、Issue管理、ダッシュボードとメトリクス、多言語解析、SCM連携、拡張機能、Web APIとWebhookなどを提供します。

静的解析では、プログラムを実行せずにソースコードを調べ、バグや脆弱性、コードスメルを検出します。次のPython例には、未使用import、ハードコードされた認証情報、未定義変数の参照があります。

```python
import json  # unused import

def login_user(username, password):
    if username == "admin" and password == "SuperSecret123":
        print("Login successful")
        return True
    else:
        return False

def calculate_area(radius):
    pi = 3.14
    return pii * radius * radius  # typo: pii is undefined
```

## MCPから解析する

MCP対応クライアントから、例えば次のように依頼できます。

> `@test.py` を静的解析し、結果をJSONにまとめて

出力にはファイル名、Issueの種類と重要度、説明、行番号、該当コードなどが含まれます。これにより、問題の場所と修正の手掛かりを会話の中で確認できます。

## まとめ

MCPによる解析は、ファイルを素早く確認する用途に便利です。サーバー側の本格的な解析が必要な場合は、SonarScannerなどを使った通常の分析と使い分けてください。

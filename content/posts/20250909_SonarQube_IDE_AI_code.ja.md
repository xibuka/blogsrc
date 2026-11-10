---
title: "AI生成コードの品質を高めるSonarQube IDEの活用"
date: 2025-09-09T23:49:19+09:00
draft: false
tags:
- IDE
- SonarQube
- SonarLint
- codequality
- AI駆動開発
---

AI生成コードには、OWASP Top 10に関わる脆弱性や潜在的なバグが含まれることがあります。[Qiitaの記事](https://qiita.com/xibuka/items/0c645116f4750105d72d)をもとに、以前SonarLintと呼ばれていたSonarQube IDEを使って、生成コードをIDE内で解析する方法を紹介します。

## VS Codeにインストール

SonarQube IDEはVS Code、Cursor、Windsurf、Trae、JetBrains、Eclipseなどで利用できます。VS Codeでは拡張機能マーケットプレイスでSonarQubeを検索し、Installをクリックします。インストール後は、入力中のコードをリアルタイムに解析できます。

![VS Code拡張機能でSonarQube IDEをインストール](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/8d53e4ed-e12d-44d6-b823-4bb1cf7360f9.png)

![VS Code上でコードをリアルタイム解析](https://assets-eu-01.kc-usercontent.com/b1eeb429-d9e0-0100-be87-468f6802040a/d201849f-e449-4e0c-b951-c615bdb347c6/sq-vscode-run-analysis.gif)

## AI生成コードを解析する

記事ではVS CodeのターミナルからClaude Codeに、Three.jsを使ってSonarQubeロゴを3Dピクセルスタイルで表示するページを作成するよう依頼しています。生成された `index.html` をSonarQube IDEで開くと、エラーや脆弱性を検出でき、指摘を選ぶと修正方法の提案が表示されます。

```text
create a webpage which can show the sonarqube logo in 3d pixel style using threeJS. The page need to be interactiveabe like zoom in and out. Make the page a clear production-ready and detailed the pixel looks.
```

![AIが生成したWebページ](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/7cdf5044-03c0-4833-b06c-16e9ddd7155b.png)

![生成された3D SonarQubeロゴ](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/2c6e0226-bfc7-4e7f-80d2-74fbca4b1175.gif)

例として、エラー時に曖昧なログを出し、問題を適切に処理していないコードがあります。

```javascript
try {
  return chargeCard(amount, cardNumber);
} catch (error) {
  console.log("Error occurred");
  return false;
}
```

ページ自体が表示できても、エラー処理が不十分な場合があります。IDEの指摘を確認し、ログや例外処理を改善することで品質を高められます。

![SonarQube IDEの解析結果と修正提案](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/5f6f09eb-f7bf-457f-9323-cab70f80c17a.png)

## サーバー連携による活用

SonarQube IDEをSonarQube Serverへ接続すると、ローカルの解析結果をチームで一元管理し、技術的負債やセキュリティリスクを可視化できます。またJenkinsやGitHub Actionsと統合し、ビルドごとに解析してQuality Gateを適用できます。サーバーのレポートやトレンド分析で、品質改善の状況を追うこともできます。

## まとめ

IDE内の解析は、AIが作成したコードの潜在的な問題を早い段階で見つける手段になります。サーバー連携やCI/CDを加えることで、個人の編集時からチーム全体の品質管理まで広げられます。

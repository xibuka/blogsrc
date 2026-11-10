---
title: "使用 SonarQube IDE 提升 AI 生成代码的质量"
description: "介绍如何用 SonarQube IDE 实时分析 AI 生成代码，在开发过程中发现并修复问题。"
date: 2025-09-09T23:49:19+09:00
draft: false
tags:
- IDE
- SonarQube
- SonarLint
- codequality
- AI驱动开发
---

AI 生成的代码可能包含 OWASP Top 10 相关漏洞或潜在 Bug。本文根据 [Qiita 原文](https://qiita.com/xibuka/items/0c645116f4750105d72d)，介绍如何使用以前称为 SonarLint 的 SonarQube IDE，在 IDE 中分析生成代码。

## 安装到 VS Code

SonarQube IDE 支持 VS Code、Cursor、Windsurf、Trae、JetBrains 和 Eclipse 等环境。在 VS Code 扩展市场搜索 SonarQube 并点击 Install。安装后即可实时分析正在编写的代码。

![在 VS Code 扩展中安装 SonarQube IDE](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/8d53e4ed-e12d-44d6-b823-4bb1cf7360f9.png)

![在 VS Code 中实时分析代码](https://assets-eu-01.kc-usercontent.com/b1eeb429-d9e0-0100-be87-468f6802040a/d201849f-e449-4e0c-b951-c615bdb347c6/sq-vscode-run-analysis.gif)

## 分析 AI 生成的代码

原文在 VS Code 终端中使用 Claude Code 生成一个 Three.js 网页，用 3D 像素风展示 SonarQube Logo。用 SonarQube IDE 打开生成的 `index.html` 后，可以发现错误和漏洞；点击问题还可以查看修复建议。

```text
create a webpage which can show the sonarqube logo in 3d pixel style using threeJS. The page need to be interactiveabe like zoom in and out. Make the page a clear production-ready and detailed the pixel looks.
```

![AI 生成的网页](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/7cdf5044-03c0-4833-b06c-16e9ddd7155b.png)

![生成的 3D SonarQube Logo](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/2c6e0226-bfc7-4e7f-80d2-74fbca4b1175.gif)

例如，下面的代码在发生错误时只输出含糊的日志，没有妥善处理问题：

```javascript
try {
  return chargeCard(amount, cardNumber);
} catch (error) {
  console.log("Error occurred");
  return false;
}
```

即使页面能够正常显示，错误处理仍可能不充分。检查 IDE 的提示并改进日志和异常处理，有助于提升代码质量。

![SonarQube IDE 分析结果与修复建议](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/5f6f09eb-f7bf-457f-9323-cab70f80c17a.png)

## 连接服务器进一步管理

将 SonarQube IDE 连接到 SonarQube Server 后，可以集中管理团队成员本地分析的结果，并查看技术债务和安全风险。还可以集成 Jenkins 或 GitHub Actions，在每次构建时运行分析并使用 Quality Gate。服务器端的报告和趋势图也便于跟踪质量改进情况。

## 总结

IDE 分析可以尽早发现 AI 编写代码中的潜在问题。再结合服务器和 CI/CD，可从个人编辑阶段扩展到团队质量管理。

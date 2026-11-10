---
title: "SonarQube × MCP 实战：让 AI 根据静态分析结果修复代码"
date: 2025-12-14T23:49:19+09:00
draft: false
tags:
- SonarQube
- 静态分析
- MCP
- Gemini
- AI编程
---

AI 提高了代码编写速度，但查看分析结果和手动修复也可能成为新的负担。本文根据 [Qiita 原文](https://qiita.com/xibuka/items/1377f143d9c32838a90c)，介绍如何连接 SonarQube 与 MCP，让 AI Agent 获取并修复 Issue。

## SonarQube MCP Server

过去需要从 SonarQube 页面复制 Issue，再粘贴到 AI 聊天中请求修复。使用 MCP 后，AI 客户端可以通过 SonarQube API 获取 Issue、读取本地源代码，并将修复写入文件。

## 架构与处理流程

使用 Gemini 作为 Agent，连接本地源代码、SonarQube MCP Server 和 SonarQube Server。流程分为四步：

![使用 SonarQube MCP 自动修复代码的架构图](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/757f6678-b58c-4e55-9c1a-4d7f55216959.png)

1. AI Agent 根据提示生成代码
2. SonarScanner 执行静态分析，并把结果发送到 SonarQube Server
3. 通过 MCP Server 获取分析产生的 Issue
4. AI Agent 结合代码上下文修复 Issue

需要 Docker、SonarScanner CLI 和 Gemini CLI（或其他 MCP 客户端）。

## 准备 SonarQube Server 和 MCP 客户端

```bash
docker run -d --name sonarqube \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  -p 9000:9000 \
  sonarqube:community
```

访问 `http://localhost:9000`，创建 `mcp-demo` 项目和 User Token。使用 Gemini CLI 时，在 `~/.gemini/settings.json` 中添加 MCP Server 配置：

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

请替换为自己的 Token 和 URL。然后从 MCP 客户端调用 `get_system_health` 验证连接。MCP Server 本身运行在本地 Docker 容器中。

## 分析与修复循环

先让 AI 生成一个 JavaScript 数独游戏，包含 `index.html`、`style.css` 和 `script.js`。随后运行 SonarScanner：

```bash
sonar-scanner \
  -Dsonar.projectKey=mcp-demo \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=<your-token>
```

分析完成后，请 AI 检查 `mcp-demo` 项目中的 Issue。MCP 工具 `search_sonar_issues_in_projects` 返回了 11 个 Issue，涉及认知复杂度、函数位置、颜色对比、数组创建和数值转换等问题。

再让 Agent 根据 Issue 修复代码，包括重构复杂函数、改善颜色对比并使用推荐的 API。最后重新扫描，确认没有未解决的 Issue。

## 总结

这种方案让 AI Agent 循环执行“生成代码 → 分析 → 获取 Issue → 修复”。MCP Server 连接 AI 与 SonarQube，免去了手动复制分析结果的步骤。修复后仍应重新分析并检查结果。

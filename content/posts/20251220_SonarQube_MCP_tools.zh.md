---
title: "SonarQube MCP Server 可用工具一览"
description: "按功能整理 SonarQube MCP Server 的工具，涵盖 Issue 搜索、Quality Gate 检查、指标查询等用途。"
date: 2025-12-20T23:49:19+09:00
draft: false
tags:
- SonarQube
- 静态分析
- MCP
- SCA
---

本文根据 [Qiita 原文](https://qiita.com/xibuka/items/6d18a1a04f4c1276f220)，按类别整理 SonarQube MCP Server 提供的工具。通过 MCP，AI 助手可以访问 SonarQube 数据和分析能力。

## 工具类别

| 类别 | 主要工具 | 用途 |
| --- | --- | --- |
| 代码分析 | `analyze_code_snippet`, `analyze_file_list`, `toggle_automatic_analysis` | 分析代码片段和文件，切换 IDE 自动分析 |
| 依赖风险 | `search_dependency_risks` | 搜索项目的依赖风险 |
| Enterprise | `list_enterprises` | 列出 SonarQube Cloud Enterprise |
| Issue | `change_sonar_issue_status`, `search_sonar_issues_in_projects` | 搜索 Issue 并更改状态 |
| 项目与组合 | `search_my_sonarqube_projects`, `list_portfolios` | 搜索项目和 Portfolio |
| Quality Gate | `get_project_quality_gate_status`, `list_quality_gates` | 查询门禁状态和定义 |
| 指标 | `get_component_measures`, `search_metrics` | 获取覆盖率、复杂度等指标 |
| 规则与源码 | `show_rule`, `list_rule_repositories`, `get_raw_source`, `get_scm_info` | 查询规则、源码和 SCM 信息 |
| 系统 | `get_system_health`, `get_system_info`, `get_system_logs`, `get_system_status`, `ping_system` | 检查服务器状态和日志 |
| Webhook | `create_webhook`, `list_webhooks` | 创建和列出 Webhook |

`search_dependency_risks` 需要 SonarQube Server 2025.4 Enterprise 或更高版本，并启用 Advanced Security。其他工具也可能受 Server/Cloud 版本和权限限制。

## 使用方式

组合这些工具后，AI 助手可以搜索 Issue、检查 Quality Gate、获取指标，以及查看规则或源代码。使用前请确认权限，并明确指定目标项目和分支。

详情请参阅 [SonarQube MCP Server 官方文档](https://docs.sonarsource.com/sonarqube-server/)。

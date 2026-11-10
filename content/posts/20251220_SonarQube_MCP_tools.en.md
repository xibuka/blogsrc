---
title: "Available Tools in the SonarQube MCP Server"
date: 2025-12-20T23:49:19+09:00
draft: false
tags:
- SonarQube
- static analysis
- MCP
- SCA
---

Based on the [Qiita article](https://qiita.com/xibuka/items/6d18a1a04f4c1276f220), this post groups the tools exposed by the SonarQube MCP Server. Through MCP, AI assistants can access SonarQube data and analysis capabilities.

## Tool categories

| Category | Main tools | Purpose |
| --- | --- | --- |
| Code analysis | `analyze_code_snippet`, `analyze_file_list`, `toggle_automatic_analysis` | Analyze snippets and files; toggle IDE auto-analysis |
| Dependency risks | `search_dependency_risks` | Search project dependency risks |
| Enterprise | `list_enterprises` | List SonarQube Cloud enterprises |
| Issues | `change_sonar_issue_status`, `search_sonar_issues_in_projects` | Search issues and change their status |
| Projects / Portfolios | `search_my_sonarqube_projects`, `list_portfolios` | Search projects and portfolios |
| Quality Gates | `get_project_quality_gate_status`, `list_quality_gates` | Retrieve gate status and definitions |
| Metrics | `get_component_measures`, `search_metrics` | Retrieve coverage, complexity, and other measures |
| Rules / Sources | `show_rule`, `list_rule_repositories`, `get_raw_source`, `get_scm_info` | Retrieve rules, source, and SCM information |
| System | `get_system_health`, `get_system_info`, `get_system_logs`, `get_system_status`, `ping_system` | Check server health and logs |
| Webhooks | `create_webhook`, `list_webhooks` | Create and list webhooks |

`search_dependency_risks` requires SonarQube Server 2025.4 Enterprise or later with Advanced Security enabled. Other tools may also have edition, deployment, or permission requirements.

## Putting the tools to work

Together, these tools let an AI assistant search issues, check Quality Gates, retrieve metrics, and inspect rules or source code. Check permissions and specify the target project and branch before invoking them.

See the [official SonarQube MCP Server documentation](https://docs.sonarsource.com/sonarqube-server/) for details.

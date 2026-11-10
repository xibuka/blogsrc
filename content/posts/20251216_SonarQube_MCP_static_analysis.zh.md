---
title: "SonarQube MCP Server 功能介绍：静态代码分析"
date: 2025-12-16T23:49:19+09:00
draft: false
tags:
- SonarQube
- 静态分析
- MCP
- MCP服务器
---

本文根据 [Qiita 原文](https://qiita.com/xibuka/items/08db95094091358d2c03)，介绍 SonarQube MCP Server 的静态代码分析功能。MCP Server 可以独立检查代码，因此无需先配置 SonarScanner 或 IDE 就能进行快速检查。不过，复杂的数据流分析和深入的漏洞检测仍需要常规 SonarQube 分析。

## 主要功能

除了静态分析，MCP Server 还提供 Quality Gate、Issue 管理、仪表板和指标、多语言分析、SCM 集成、扩展能力，以及 Web API 和 Webhook。

静态分析无需运行程序即可检查源代码，发现 Bug、漏洞和代码异味。下面的 Python 示例包含未使用的导入、硬编码凭证和未定义变量引用：

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

## 通过 MCP 执行分析

可以在支持 MCP 的客户端中提出类似请求：

> 对 `@test.py` 执行静态分析，并将结果整理为 JSON

结果可包含文件名、Issue 类型和严重程度、说明、行号及相关代码。这样可以在对话中快速定位问题并获取修复线索。

## 总结

MCP 分析适合快速检查文件。若需要服务器端的完整分析，应结合 SonarScanner 等常规分析方式使用。

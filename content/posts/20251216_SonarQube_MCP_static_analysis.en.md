---
title: "SonarQube MCP Server Features: Static Code Analysis"
description: "Explore SonarQube MCP Server capabilities and setup, then see how an AI assistant can inspect static-analysis issues and Quality Gates."
date: 2025-12-16T23:49:19+09:00
draft: false
tags:
- SonarQube
- static analysis
- MCP
- MCP server
---

Based on the [Qiita article](https://qiita.com/xibuka/items/08db95094091358d2c03), this post introduces static code analysis with the SonarQube MCP Server. The MCP server can inspect code on its own, making quick checks possible without setting up SonarScanner or an IDE. Advanced data-flow analysis and deeper vulnerability detection still require a regular SonarQube analysis.

## Main capabilities

In addition to static analysis, the MCP Server provides Quality Gates, issue management, dashboards and metrics, multi-language analysis, SCM integration, extensibility, and Web APIs and webhooks.

Static analysis examines source code without running it and can detect bugs, vulnerabilities, and code smells. This Python example contains an unused import, hard-coded credentials, and a reference to an undefined variable:

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

## Analyze through MCP

From an MCP-capable client, you can ask:

> Run static analysis on `@test.py` and format the results as JSON.

The response can include the file, issue type and severity, explanation, line number, and relevant code. This makes it easier to locate problems and review possible fixes in a conversation.

## Summary

MCP-based analysis is useful for quick file checks. For comprehensive server-side analysis, use it alongside a regular scan with SonarScanner.

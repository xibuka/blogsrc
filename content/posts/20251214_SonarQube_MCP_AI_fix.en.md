---
title: "SonarQube × MCP: Fixing Static Analysis Issues with AI Coding"
date: 2025-12-14T23:49:19+09:00
draft: false
tags:
- SonarQube
- static analysis
- MCP
- Gemini
- AI coding
---

AI has made code generation faster, but reviewing findings and fixing them manually can become a new bottleneck. Based on the [Qiita article](https://qiita.com/xibuka/items/1377f143d9c32838a90c), this post shows how to connect SonarQube and MCP so an AI agent can retrieve and fix issues.

## SonarQube MCP Server

Previously, developers had to copy issues from SonarQube and paste them into an AI chat to request fixes. With MCP, an AI client can retrieve issues through the SonarQube API, read local source files, and apply changes to those files.

## Architecture and workflow

Use Gemini as the agent and connect local source code, the SonarQube MCP Server, and SonarQube Server. The cycle has four steps:

![Architecture for AI code repair with SonarQube MCP](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/757f6678-b58c-4e55-9c1a-4d7f55216959.png)

1. The AI agent generates code from a prompt.
2. SonarScanner analyzes the code and sends the results to SonarQube Server.
3. The agent retrieves the resulting issues through the MCP Server.
4. The agent uses source context to fix the issues.

You need Docker, SonarScanner CLI, and Gemini CLI (or another MCP-capable client).

## Set up SonarQube Server and the MCP client

```bash
docker run -d --name sonarqube \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  -p 9000:9000 \
  sonarqube:community
```

Open `http://localhost:9000`, create an `mcp-demo` project, and generate a User Token. For Gemini CLI, register the MCP Server in `~/.gemini/settings.json`:

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

Replace the token and URL with values from your environment. Call `get_system_health` from the MCP client to verify connectivity. The MCP Server itself runs locally in a Docker container.

## Run the analysis and repair cycle

First, ask the AI to generate a JavaScript Sudoku game with `index.html`, `style.css`, and `script.js`. Then run SonarScanner:

```bash
sonar-scanner \
  -Dsonar.projectKey=mcp-demo \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=<your-token>
```

After analysis, ask the agent to inspect issues in `mcp-demo`. The `search_sonar_issues_in_projects` MCP tool returned 11 issues covering cognitive complexity, function placement, contrast, array creation, and numeric conversions.

Ask the agent to fix the findings. It refactors the complex function, improves contrast, and applies the recommended APIs. Run another scan to confirm there are no open issues.

## Summary

This setup lets an AI agent repeat the cycle “generate → analyze → retrieve issues → fix.” The MCP Server connects the agent to SonarQube and removes the manual copy-and-paste step. Re-run the analysis and review the results after applying fixes.

---
title: "Trying the SonarQube CLI: Simpler, Smarter Static Analysis"
description: "Learn how to install and use the SonarQube CLI to analyze a project locally or in CI, with a simpler workflow for static code analysis."
date: 2026-05-05T23:49:19+09:00
draft: false
tags:
- SonarQube
---

Based on the [Qiita article](https://qiita.com/xibuka/items/a74d6cc7705c28258186), this post summarizes the main capabilities of the `sonar` command. While the traditional `sonar-scanner` focuses on CI/CD analysis, the new CLI is designed with local development and AI agent workflows in mind.

## Authentication

Run `sonar auth login` to authenticate in a browser. Use `-s` to specify a SonarQube Server or SonarQube Cloud US instance.

```bash
sonar auth login
sonar auth login -s https://my-sonarqube.io
sonar auth status
```

Credentials are stored in the OS keychain or a similar secure store. Use `sonar auth status` to check the server and connection state.

## List projects and issues

```bash
sonar list projects
sonar list issues -p <project-key>
```

The commands return JSON, which you can filter with `jq`. When a project has many issues, use a command such as `head` to limit the output.

## Analyze local files

```bash
sonar analyze secrets app.ts
sonar analyze sqaa --file app.ts -p <project-key>
sonar verify --file app.ts -p <project-key>
```

`secrets` uses a local analyzer to detect secrets in files. `sqaa` uses SonarQube Cloud Agentic Analysis to analyze a specified file and report issues. Project and branch options provide the right analysis context.

## Scan for secrets with a Git hook

```bash
sonar integrate git
```

Follow the prompts to select a repository and install either a `pre-commit` or `pre-push` hook. The hook scans files before a commit or push and can block the operation when it finds secrets. Ensure `sonar` is available on the PATH used by the hook.

The CLI brings authentication, issue lookup, local analysis, and Git hook integration together under the `sonar` command.

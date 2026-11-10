---
title: "Automatically Analyze Pull Requests with GitHub Actions and SonarQube"
date: 2025-12-04T23:49:19+09:00
draft: false
tags:
- GitHub
- SonarQube
- CICD
---

Based on the [Qiita article](https://qiita.com/xibuka/items/14f127a56bc24924c83b), this post shows how to run SonarQube Server analysis whenever a pull request (PR) is created or updated. This helps detect bugs and code smells before review.

## Prepare SonarQube

Create a project in SonarQube for the target repository and note its Project Key. Then go to My Account > Security, generate an Analysis Token, and copy it for later use.

## Configure GitHub Secrets

In the repository, open Settings > Secrets and variables > Actions and add these Repository Secrets:

| Name | Value |
| --- | --- |
| `SONAR_TOKEN` | The token created in SonarQube |
| `SONAR_HOST_URL` | The SonarQube Server URL |

GitHub Actions runs in the cloud and cannot reach a SonarQube instance at `localhost` on your computer. Provide a server accessible over the internet, or use a tunnel such as ngrok for a trial.

## Create the workflow

Add `.github/workflows/sonar-analysis.yml`:

```yaml
name: SonarQube Analysis

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  build:
    name: Build and Analyze
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: SonarQube Scan
        uses: sonarsource/sonarqube-scan-action@v2.0.1
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
        with:
          args: >
            -Dsonar.projectKey=my-project
```

Replace `my-project` with your Project Key. `fetch-depth: 0` retrieves the full Git history so SonarQube can analyze SCM information.

## Verify the results on a PR

Push a branch change and create a PR. Check the job in the Actions Checks tab. After it succeeds, open the project in SonarQube to review the PR analysis, including Bugs, Vulnerabilities, Code Smells, and the affected source lines.

## Summary

Running SonarQube analysis automatically when a PR is opened or updated makes quality issues visible earlier. You can also add a Quality Gate to prevent merging PRs that do not meet your standards.

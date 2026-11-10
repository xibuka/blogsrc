---
title: "Streamlining Technical Debt Management with SonarQube Automatic Issue Assignment"
description: "Learn how SonarQube automatically assigns issues to the developers who introduced them, helping teams make code-quality ownership clearer."
date: 2026-04-20T23:49:19+09:00
draft: false
tags:
- SonarQube
- technical debt
- code quality
---

Based on the [Qiita article](https://qiita.com/xibuka/items/d4bd739ab06e28bfa919), this post introduces SonarQube Automatic Issue Assignment. A scan can produce many issues, and deciding who should own each one adds overhead. This feature uses SCM data to assign issues to developers associated with the affected code.

## How automatic assignment works

During analysis, SonarQube obtains SCM information such as Git history and identifies the last author of the line where an issue was found. It matches the SCM committer to a SonarQube user by email address and assigns the issue to that user.

The process is:

1. Collect last-change information for each line during analysis, similar to `git blame`.
2. Use the issue location to identify the user who last committed the affected line.
3. Map the SCM email address to a SonarQube account.
4. Assign the issue to the matching user.

## Verify the behavior

Create SonarQube users whose email addresses match those used in SCM. The original article uses GitHub integration and has three corresponding accounts commit code.

![SonarQube user settings](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/caefca22-a964-4661-b12f-5801cca8c3e9.png)

Each corresponding GitHub account commits code.

![Commit code from GitHub](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/14f8d156-98f7-4544-8604-9db21951b0f2.png)

After a commit, run an analysis. Detected issues are automatically assigned to the user who last changed the relevant code. Correct SCM integration and email mapping are prerequisites.

![Automatically assigned issue](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/4c2fcc7e-cd4f-4275-ac1e-5efdc559a377.png)

## Summary

With SCM integration configured, teams can reduce manual triage and route improvement work to developers familiar with the affected code. If issues tend to remain unassigned, check the automatic assignment setup and user email mappings.

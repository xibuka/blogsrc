---
title: "Essential Security Basics for Vibe Coding: SAST, SCA, and DAST"
description: "Understand SAST, SCA, and DAST for Vibe Coding, and learn how each approach detects risks in source code, dependencies, and running apps."
date: 2025-09-04T23:49:19+09:00
draft: false
tags:
- SonarQube
- SonarLint
- codequality
- SAST
- VibeCoding
---

Even when coding in a productive Vibe Coding flow, security oversights can happen. Based on the [Qiita article](https://qiita.com/xibuka/items/6a1ab688bfe48be41566), this post introduces three ways to check code under development, dependency libraries, and running applications.

## SAST: inspect source code

SAST (Static Application Security Testing) analyzes source code without running the program and finds unsafe patterns. It can detect SQL injection, XSS, and hard-coded passwords or API keys. With SonarQube IDE integrated into an IDE, findings can be raised while coding.

## SCA: inspect dependencies

SCA (Software Composition Analysis) identifies open-source libraries and frameworks used by a project and checks for known vulnerabilities and license issues. When adding a package, it helps determine whether the selected version has known risks.

## DAST: inspect a running application

DAST (Dynamic Application Security Testing) tests an application while it is running, from the outside. It can find server configuration problems and authentication weaknesses that are visible only in the runtime environment. If SAST checks the blueprint, DAST tests the finished application from the outside.

## Combine the three checks

| Method | Main target | When to use it |
| --- | --- | --- |
| SAST | Source code | From early development onward |
| SCA | OSS libraries and other dependencies | Continuously during development and operation |
| DAST | A running application | Later development and test environments |

Using only one method is not enough. Checking source code, dependencies, and running applications covers different kinds of risk.

## Summary

To keep applications built with Vibe Coding secure, combine SAST, SCA, and DAST at appropriate stages. In addition to checking code as it is written, keep reviewing dependencies and the running application.

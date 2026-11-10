---
title: "让 Vibe Coding 更稳健的基础知识：SAST、SCA 与 DAST"
date: 2025-09-04T23:49:19+09:00
draft: false
tags:
- SonarQube
- SonarLint
- codequality
- SAST
- VibeCoding
---

即使在轻松顺畅地进行 Vibe Coding，也需要注意可能发生的安全疏漏。本文根据 [Qiita 原文](https://qiita.com/xibuka/items/6a1ab688bfe48be41566)，介绍三种检查方式：检查开发中的代码、依赖库以及运行中的应用。

## SAST：检查源代码

SAST（Static Application Security Testing）无需运行程序即可分析源代码，发现不安全的写法。它可以检测 SQL 注入、XSS，以及硬编码的密码或 API Key。将 SonarQube IDE 集成到 IDE 后，可在开发时及时提示问题。

## SCA：检查依赖库

SCA（Software Composition Analysis）会识别项目使用的开源库和框架，并检查已知漏洞及许可证问题。添加新依赖时，可以确认所用版本是否存在已知风险。

## DAST：检查运行中的应用

DAST（Dynamic Application Security Testing）从外部测试实际运行的应用。它可以发现服务器配置错误、认证功能弱点等只有在运行环境中才能观察到的问题。如果说 SAST 是检查设计图，DAST 就是从外部测试已建成的应用。

## 组合使用三种检查

| 方法 | 主要对象 | 适用阶段 |
| --- | --- | --- |
| SAST | 源代码 | 开发初期至开发过程中 |
| SCA | OSS 库等依赖项 | 开发期间并持续到运行阶段 |
| DAST | 正在运行的应用 | 开发后期或测试环境 |

仅使用其中一种并不充分。分别检查代码、依赖关系和运行中的应用，可以覆盖不同类型的风险。

## 总结

要让 Vibe Coding 创建的应用更安全，需要在适当阶段组合使用 SAST、SCA 和 DAST。除了编写代码时的检查，也要持续关注依赖关系和运行中的应用。

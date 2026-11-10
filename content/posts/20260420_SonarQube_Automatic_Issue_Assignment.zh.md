---
title: "使用 SonarQube 自动分配 Issue，简化代码债务管理"
date: 2026-04-20T23:49:19+09:00
draft: false
tags:
- SonarQube
- 技术债务
- 代码质量
---

本文根据 [Qiita 原文](https://qiita.com/xibuka/items/d4bd739ab06e28bfa919)，介绍 SonarQube 的 Automatic Issue Assignment。代码扫描后可能产生大量 Issue，逐一决定负责人会增加工作量。该功能利用 SCM 信息，自动将 Issue 分配给相关代码的开发者。

## 自动分配的工作方式

分析时，SonarQube 会获取 Git 等 SCM 信息，并识别 Issue 所在行的最后修改者。它通过电子邮件地址将 SCM 提交者与 SonarQube 用户匹配，然后把 Issue 分配给对应用户。

处理过程如下：

1. 分析时获取每行的最后修改者信息（类似 `git blame`）
2. 根据 Issue 所在位置找出最后提交该行的用户
3. 将 SCM 中的电子邮件地址映射到 SonarQube 用户
4. 把 Issue 分配给匹配的用户

## 验证功能

在 SonarQube 中注册用户，并确保其邮箱与 SCM 中使用的邮箱一致。原文使用 GitHub 集成，由对应 SonarQube 用户的三个 GitHub 账户分别提交代码。

![SonarQube 用户设置](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/caefca22-a964-4661-b12f-5801cca8c3e9.png)

然后由这三个对应的 GitHub 账户分别提交代码。

![从 GitHub 提交代码](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/14f8d156-98f7-4544-8604-9db21951b0f2.png)

提交后运行分析，检测到的 Issue 会自动分配给修改相关代码的用户。此功能依赖正确的 SCM 集成和邮箱映射。

![Issue 自动分配结果](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/4c2fcc7e-cd4f-4275-ac1e-5efdc559a377.png)

## 总结

配置 SCM 集成后，可以减少手动分配 Issue 的工作，并将改进任务交给熟悉相关代码的开发者。如果团队中的分析 Issue 经常无人处理，可以检查自动分配设置以及用户邮箱映射是否正确。

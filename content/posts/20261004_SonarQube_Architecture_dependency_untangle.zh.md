---
title: "模块内依赖纠缠，SonarQube 如何将其可视化？"
description: "介绍如何用 SonarQube Architecture 可视化模块依赖与循环依赖，并通过 Request Removal 将不合理依赖转为可跟踪的 Issue。"
date: 2026-10-04T23:49:19+09:00
draft: false
tags:
- SonarQube
- Architecture
- codequality
---

## 什么是模块内依赖纠缠？

当模块中的类和组件彼此之间无序依赖时，问题会悄悄累积：

![模块内依赖纠缠示例](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/25e63fc9-6159-4ddb-aed4-ae55c7a2ce1e.png)

1. **成为技术债务的温床**

   依赖关系越复杂，一处修改就越可能意外影响其他位置。每次修复都需要花更多时间调查影响范围，久而久之便会出现“不敢改动”的代码。这是典型的技术债务；重构越晚，维护成本增长得越快。

2. **无法实现松耦合**

   模块本应能够独立测试、修改和复用。但循环依赖或跨层引用会让模块难以拆分，也难以单独测试。由此会导致修改影响范围难以预测、单元测试需要大量 Mock，以及新成员理解整体结构需要很长时间等问题。

依赖纠缠通常不是一次性形成的，而是由日常开发中一个个“顺手引用”逐渐积累。如果没有可视化机制，往往要等技术债务达到临界点才会察觉。

## SonarQube Architecture 功能

SonarQube 为此提供专门的架构管理功能 Architecture。代码分析时，它会自动提取依赖关系图，并以可交互的方式呈现。无需额外配置或手工整理，只需运行常规静态分析即可使用。每次分析都会刷新图表，反映当前代码的依赖结构。

![SonarQube Architecture 可视化的依赖关系](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/bfb97ad9-6df4-4735-99a9-31957b84ac58.png)

循环依赖等结构性问题也会被自动检测并显示在图中。无需另行安装工具或编写特殊规则，就能在日常构建和分析流程中发现依赖纠缠。

## 使用 Request Removal 将纠缠转化为任务

发现纠缠后，如果判断某组件之间的依赖不应该存在，下一步就是修复。此时可以使用 `Request Removal` 功能。

![对依赖关系使用 Request Removal](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/7fe237d6-6f2c-42d3-81a5-d39483f71330.png)

选择希望删除的依赖关系并点击“Request removal”后，下一次分析会将该位置自动生成为常规 SonarQube Issue。这样它就成为正式登记的待修复事项，并会持续跟踪到问题解决。

![由依赖移除请求生成的 Issue](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/73ee0c02-8815-4a03-bc8c-5343f8cbaf3c.png)

生成的 Issue 与其他代码质量问题一样处理：可以分配给负责工程师，也可以设置为 Quality Gate 的检查条件。

## 总结

模块内的依赖纠缠会在不知不觉中积累技术债务，并破坏松耦合设计。SonarQube Architecture 可在常规静态分析中自动生成依赖地图并检测纠缠。使用 `Request Removal` 后，还能把发现的依赖问题登记为 Issue，并在现有开发流程中跟进解决。

与其偶尔进行一次大型重构，更现实的做法是持续可视化并制定规则。SonarQube Architecture 为此提供了基础。

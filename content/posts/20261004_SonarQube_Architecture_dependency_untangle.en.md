---
title: "Visualizing Tangled Module Dependencies with SonarQube"
description: "Learn how SonarQube Architecture visualizes module dependencies and cycles, and how Request Removal turns unwanted dependencies into trackable issues."
date: 2026-10-04T23:49:19+09:00
draft: false
tags:
- SonarQube
- Architecture
- codequality
---

## What is dependency tangling within a module?

When classes and components inside modules depend on one another without a clear structure, several problems quietly accumulate:

![Example of tangled dependencies within a module](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/25e63fc9-6159-4ddb-aed4-ae55c7a2ce1e.png)

1. **It becomes a source of technical debt.**

   The more tangled the dependencies, the greater the risk that one change will affect unexpected areas. Investigating the impact of each change becomes more expensive, until the codebase contains parts that developers are afraid to touch. This is a typical form of technical debt, and delaying refactoring makes maintenance costs grow.

2. **Loose coupling breaks down.**

   Modules should be independently testable, changeable, and reusable. Circular dependencies or references across layers make it difficult to extract or test a module in isolation. As a result, change impact becomes hard to predict, unit tests require extensive mocking, and new team members need longer to understand the system.

Dependency tangles rarely appear all at once. They grow from small, everyday “while I’m here” references. Without a way to visualize them, teams may not notice until the debt reaches a critical point.

## SonarQube Architecture

SonarQube provides a dedicated architecture management feature called Architecture. During code analysis, it automatically extracts dependency graphs and presents them interactively. No extra setup or manual work is required; run the regular static analysis. The graph updates with each analysis to reflect the current codebase.

![Dependencies visualized in SonarQube Architecture](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/bfb97ad9-6df4-4735-99a9-31957b84ac58.png)

Structural problems such as circular dependencies are detected and shown in the graph. Teams can discover tangles through their regular build and analysis workflow without installing another tool or writing special rules.

## Turn tangles into tasks with Request Removal

After finding a tangle, you may decide that a dependency between two components should not exist. The next step is to fix it. The `Request Removal` feature helps make that work trackable.

![Requesting removal of a dependency](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/7fe237d6-6f2c-42d3-81a5-d39483f71330.png)

Select the dependency to remove and click “Request removal.” Starting with the next analysis, SonarQube creates a regular Issue for that location. The work is formally registered and remains tracked until it is resolved.

![Issue created from a dependency removal request](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/73ee0c02-8815-4a03-bc8c-5343f8cbaf3c.png)

The generated Issue can be handled like other code quality issues: assign it to an engineer or use it as a Quality Gate condition.

## Summary

Tangled module dependencies quietly increase technical debt and undermine loose coupling. SonarQube Architecture visualizes dependencies and detects tangles as part of regular static analysis. With `Request Removal`, teams can turn a discovered dependency into a tracked Issue and resolve it through their existing workflow.

Rather than relying on a single large refactoring, continuously visualizing dependencies and enforcing rules is a more practical approach. SonarQube Architecture provides a foundation for that work.

---
title: "使用 SonarQube 可视化测试覆盖率：实践指南"
description: "使用 JaCoCo 测量 Maven 项目的测试覆盖率，将报告导入 SonarQube，并在仪表板和源码中查看结果。"
date: 2025-12-09T23:49:19+09:00
draft: false
tags:
- Maven
- SonarQube
- 测试覆盖率
---

本文根据 [Qiita 原文](https://qiita.com/xibuka/items/b10ef5b10075fbc8e8b5)，介绍如何将 Maven Java 项目中 JaCoCo 生成的覆盖率报告导入 SonarQube。

## 获取示例项目

```bash
git clone https://github.com/wenhan-sonar/maven-example
cd maven-example
```

项目包含 `src/main/java/com/example/MyClass.java`、`src/test/java/com/example/MyClassTest.java`，以及配置 Maven 和 JaCoCo 的 `pom.xml`。

## 生成 JaCoCo 报告

JaCoCo Maven Plugin 的 `prepare-agent` 会在测试运行时收集覆盖率数据，`report` goal 则生成 XML 报告。原文中的配置示例如下：

```xml
<plugin>
  <groupId>org.jacoco</groupId>
  <artifactId>jacoco-maven-plugin</artifactId>
  <version>0.8.11</version>
  <executions>
    <execution>
      <id>prepare-agent</id>
      <goals><goal>prepare-agent</goal></goals>
    </execution>
    <execution>
      <id>report</id>
      <phase>test</phase>
      <goals><goal>report</goal></goals>
    </execution>
  </executions>
</plugin>
```

运行测试并生成报告：

```bash
mvn clean verify
```

运行后，`target/jacoco.exec` 保存二进制覆盖率数据，`target/site/jacoco/jacoco.xml` 保存 XML 报告。

## 将报告发送到 SonarQube

指定 SonarQube URL、认证 Token 和项目键后启动分析：

```bash
mvn sonar:sonar \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=<your-token> \
  -Dsonar.projectKey=maven-example-01
```

成功日志中出现 `JaCoCo XML Report Importer` 和 `ANALYSIS SUCCESSFUL`，表示报告已导入。

## 查看 SonarQube 中的结果

在项目仪表板中查看覆盖率。示例 `MyClass` 有 `coveredMethod()` 和 `uncoveredMethod()` 两个方法，而测试只调用前者，因此覆盖率为 50%。代码视图会用不同颜色标示已执行和未执行的代码行。

![SonarQube 仪表板上的覆盖率](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/98f9a57d-0c4d-4699-95c7-c5bad2de3af5.png)

![按代码行显示的覆盖率](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/6d2727e4-ba31-4331-ab37-e5c57bc0aab8.png)

Java 可使用 JaCoCo 或 Cobertura；JavaScript/TypeScript 可使用 LCOV；.NET 可使用 Visual Studio Code Coverage 或 OpenCover；Python 可使用 Coverage.py；PHP 可使用 Clover XML；Go 可使用标准覆盖率格式。基本流程都是先生成报告，再将报告路径传给 SonarScanner。

## 总结

将 JaCoCo 与 SonarQube 集成后，可以在 CI/CD 中持续查看测试覆盖率。按行展示的覆盖信息有助于发现尚未覆盖的代码。

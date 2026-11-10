---
title: "Visualizing Test Coverage with SonarQube: A Practical Guide"
date: 2025-12-09T23:49:19+09:00
draft: false
tags:
- Maven
- SonarQube
- test coverage
---

Based on the [Qiita article](https://qiita.com/xibuka/items/b10ef5b10075fbc8e8b5), this post shows how to import a JaCoCo coverage report from a Maven Java project into SonarQube.

## Get the sample project

```bash
git clone https://github.com/wenhan-sonar/maven-example
cd maven-example
```

The project includes `src/main/java/com/example/MyClass.java`, `src/test/java/com/example/MyClassTest.java`, and a `pom.xml` configured for Maven and JaCoCo.

## Generate the JaCoCo report

The JaCoCo Maven Plugin's `prepare-agent` goal collects coverage data during tests, while the `report` goal produces an XML report. The original article uses this configuration:

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

Run the tests and generate the report:

```bash
mvn clean verify
```

The run creates binary coverage data at `target/jacoco.exec` and an XML report at `target/site/jacoco/jacoco.xml`.

## Send the report to SonarQube

Specify the SonarQube URL, authentication token, and project key, then run the analysis:

```bash
mvn sonar:sonar \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=<your-token> \
  -Dsonar.projectKey=maven-example-01
```

The log should show `JaCoCo XML Report Importer` and `ANALYSIS SUCCESSFUL` when the report is imported successfully.

## Review the results in SonarQube

Check the project dashboard for coverage. The sample `MyClass` has `coveredMethod()` and `uncoveredMethod()`, but the test calls only the first method, resulting in 50% coverage. The code view highlights executed and unexecuted lines in different colors.

![Coverage percentage on the SonarQube dashboard](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/98f9a57d-0c4d-4699-95c7-c5bad2de3af5.png)

![Coverage details by source line](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/6d2727e4-ba31-4331-ab37-e5c57bc0aab8.png)

JaCoCo and Cobertura are options for Java; LCOV for JavaScript/TypeScript; Visual Studio Code Coverage and OpenCover for .NET; Coverage.py for Python; Clover XML for PHP; and the standard coverage format for Go. The common workflow is to generate a report and provide its path to SonarScanner.

## Summary

Integrating JaCoCo with SonarQube makes test coverage visible in a CI/CD pipeline. Line-level highlighting helps identify code that is not covered by tests.

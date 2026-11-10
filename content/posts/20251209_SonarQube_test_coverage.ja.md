---
title: "SonarQubeでテストカバレッジを可視化する：実践ガイド"
description: "MavenプロジェクトのテストカバレッジをJaCoCoで計測し、SonarQubeに取り込んでダッシュボードやソースコード上で可視化します。"
date: 2025-12-09T23:49:19+09:00
draft: false
tags:
- Maven
- SonarQube
- テストカバレッジ
---

[Qiitaの記事](https://qiita.com/xibuka/items/b10ef5b10075fbc8e8b5)をもとに、MavenのJavaプロジェクトでJaCoCoのカバレッジレポートをSonarQubeへ取り込む方法を紹介します。

## サンプルプロジェクト

```bash
git clone https://github.com/wenhan-sonar/maven-example
cd maven-example
```

プロジェクトには `src/main/java/com/example/MyClass.java`、`src/test/java/com/example/MyClassTest.java`、MavenとJaCoCoの設定を含む `pom.xml` があります。

## JaCoCoレポートを生成する

JaCoCo Maven Pluginの `prepare-agent` でテスト実行時に計測し、`report` goalでXMLレポートを作成します。原文の設定例は次の通りです。

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

テストとレポート生成を実行します。

```bash
mvn clean verify
```

実行後、`target/jacoco.exec` に計測データ、`target/site/jacoco/jacoco.xml` にXML形式のレポートが生成されます。

## SonarQubeへ送信する

SonarQubeサーバーURL、認証トークン、プロジェクトキーを指定して解析を実行します。

```bash
mvn sonar:sonar \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=<your-token> \
  -Dsonar.projectKey=maven-example-01
```

成功ログに `JaCoCo XML Report Importer` と `ANALYSIS SUCCESSFUL` が表示されれば、レポートが取り込まれています。

## SonarQubeで結果を確認する

プロジェクトのダッシュボードでカバレッジ率を確認できます。例の `MyClass` には `coveredMethod()` と `uncoveredMethod()` があり、テストでは前者だけを呼び出します。そのためカバレッジは50%となり、コードビューでは実行された行と未実行の行が色分けされます。

![SonarQubeダッシュボードのカバレッジ率](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/98f9a57d-0c4d-4699-95c7-c5bad2de3af5.png)

![コード行ごとのカバレッジ表示](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/6d2727e4-ba31-4331-ab37-e5c57bc0aab8.png)

JavaではJaCoCoやCobertura、JavaScript/TypeScriptではLCOV、.NETではVisual Studio Code CoverageやOpenCover、PythonではCoverage.py、PHPではClover XML、Goでは標準カバレッジ形式などを利用できます。基本的な連携は、レポートを生成し、SonarScannerにそのパスを指定する流れです。

## まとめ

JaCoCoとSonarQubeを連携すると、CI/CDでテストカバレッジを継続して確認できます。行単位の可視化によって、どのコードがテストされていないかを把握しやすくなります。

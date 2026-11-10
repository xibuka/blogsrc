---
title: "Docker ComposeでSonarQubeを手軽に起動する"
date: 2025-09-22T23:49:19+09:00
draft: false
tags:
- Sonar
- SonarQube
---

[Qiitaの記事](https://qiita.com/xibuka/items/24bf8a9441725894dd2a)では、Docker Composeを使った2種類の起動方法を紹介しています。内蔵DBを使う試用向け構成と、PostgreSQLを使う構成です。

## 準備

DockerとDocker Composeをインストールしておきます。

## 内蔵DBを使う試用向け構成

SonarQubeには評価用のH2データベースが含まれているため、DB用コンテナーなしで起動できます。データ永続化の設定がなければ、コンテナーを削除するとデータも失われるため、試用向けです。

`compose.yml` を作成します。

```yaml
version: "3"

services:
  sonarqube:
    image: sonarqube:latest
    container_name: sonarqube
    ports:
      - "9000:9000"
    environment:
      - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
    volumes:
      - ./sq-logs:/opt/sonarqube/logs
      - ./sq-data:/opt/sonarqube/data
      - ./sq-extensions:/opt/sonarqube/extensions
```

作成したディレクトリで起動します。

```bash
docker-compose up -d
```

`http://localhost:9000` にアクセスし、ログイン画面が表示されることを確認します。初期認証情報は `admin` / `admin` です。ログイン後にパスワードを変更します。

![SonarQubeのログイン画面](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/c252b55a-038c-4a91-9978-53a5ab128ea3.png)

## PostgreSQLを使う構成

本格運用向けには、SonarQubeとPostgreSQLを別コンテナーで起動します。

```yaml
services:
  sonarqube:
    image: sonarqube:latest
    ports:
      - "9000:9000"
    environment:
      SONAR_JDBC_USERNAME: sonarqube_user
      SONAR_JDBC_PASSWORD: sonarqube_pw
      SONAR_JDBC_URL: jdbc:postgresql://postgres-db:5432/sonarqube_db
      SONAR_TELEMETRY_ENABLE: "false"
    volumes:
      - ./sq-logs:/opt/sonarqube/logs
      - ./sq-data:/opt/sonarqube/data
      - ./sq-extensions:/opt/sonarqube/extensions

  postgres-db:
    image: postgres:17
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: sonarqube_user
      POSTGRES_PASSWORD: sonarqube_pw
      POSTGRES_DB: sonarqube_db
    volumes:
      - ./pg-data:/var/lib/postgresql/data
```

SonarQube側のJDBCユーザー、パスワード、URLをPostgreSQL側の設定と一致させます。Docker Composeのネットワークでは、サービス名を使ってコンテナー間通信を行います。両方のサービスのvolumeを設定し、データを永続化します。

```bash
docker-compose up -d
```

同じく `http://localhost:9000` にアクセスし、PostgreSQLへ接続して初期化が終わるまで待ちます。

## まとめ

内蔵DB構成はすばやく試す用途に、PostgreSQL構成は永続データを扱う用途に向いています。運用時はバージョンを固定し、DB認証情報を適切に管理してください。

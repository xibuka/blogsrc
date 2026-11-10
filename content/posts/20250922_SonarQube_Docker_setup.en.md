---
title: "Start SonarQube Quickly with Docker Compose"
date: 2025-09-22T23:49:19+09:00
draft: false
tags:
- Sonar
- SonarQube
---

The [Qiita article](https://qiita.com/xibuka/items/24bf8a9441725894dd2a) presents two ways to deploy SonarQube with Docker Compose: a trial setup using its embedded database and a deployment using PostgreSQL.

## Prerequisites

Install Docker and Docker Compose.

## Trial setup with the embedded database

SonarQube includes an H2 database for evaluation, so no separate database container is needed. Without persistent volumes, deleting the container also deletes its data; use this setup for trials.

Create `compose.yml`:

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

Start the service from that directory:

```bash
docker-compose up -d
```

Open `http://localhost:9000` and confirm the login page appears. The default credentials are `admin` / `admin`; change the password after signing in.

![SonarQube login page](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/c252b55a-038c-4a91-9978-53a5ab128ea3.png)

## Setup with PostgreSQL

For a persistent deployment, run SonarQube and PostgreSQL in separate containers:

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

The JDBC username, password, and URL in SonarQube must match the PostgreSQL settings. Docker Compose lets containers communicate through service names. Configure volumes for both services to persist their data.

```bash
docker-compose up -d
```

Then open `http://localhost:9000` and wait for SonarQube to connect to PostgreSQL and finish initialization.

## Summary

The embedded database is useful for a quick trial; PostgreSQL is suitable when data must persist. For actual operation, pin image versions and manage database credentials appropriately.

---
title: "Hello World! Run Your First Code Scan"
description: "A beginner-friendly walkthrough for creating a SonarQube project and running your first code scan, with step-by-step screenshots."
date: 2025-12-02T23:49:19+09:00
draft: false
tags:
- SonarQube
- SonarScanner
- codesmell
- SAST
- CodeScanning
---

Before adding static analysis to CI/CD, you can try it locally first. Based on the [Qiita article](https://qiita.com/xibuka/items/42a93ae2b401d1296052), this guide starts SonarQube Server with Docker and scans sample code with SonarScanner CLI.

## Goal and prerequisites

Scan source code and review bugs and code smells in SonarQube. You need Docker Desktop or Docker Engine and this Python file:

```python
def hello():
    print("Hello World")
    x = 10  # unused variable

hello()
```

## Start SonarQube Server

```bash
docker run -d --name sonarqube -p 9000:9000 sonarqube:community
```

Open `http://localhost:9000` in a browser and sign in with the initial username and password `admin` / `admin`. Change the password when prompted.

![SonarQube initial login page](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/b600c4f3-bb06-4146-869d-9efe61038501.png)

## Prepare a project, token, and URL

Choose [Create a local project] and create a project with the display name `hello-world`. Then go to My Account > Security and create a token, for example named `scanner-cli`. Copy the token before closing the page.

![Start creating a local project](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/a13aa65e-7eb3-4ac3-9412-cb053cc0f342.png)

![Enter the project display name](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/1e1d234a-d9ae-4b4f-a4fe-720da301952c.png)

![Confirm project settings](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/f08b92e0-bdf9-45a3-b58f-eec9e5879da9.png)

![Generate a SonarQube token](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/e89254ee-85df-46d3-a0fb-bc15614a2c2b.png)

From Docker Desktop on Windows or macOS, use `http://host.docker.internal:9000` to reach the host. On Linux, use `http://localhost:9000` or the container IP.

## Run a scan with SonarScanner CLI

From the directory containing `main.py`, replace the token and run:

```bash
docker run --rm \
  -e SONAR_HOST_URL="http://host.docker.internal:9000" \
  -e SONAR_TOKEN="<your-token>" \
  -v "$(pwd):/usr/src" \
  sonarsource/sonar-scanner-cli \
  -Dsonar.projectKey=hello-world
```

`--rm` removes the Scanner container after the scan, and `-v` mounts the current source directory at `/usr/src` inside the container. The scan succeeds when the log ends with `EXECUTION SUCCESS`.

## Review the results

Refresh the SonarQube project page at `http://localhost:9000/dashboard?id=hello-world` and open Issues. You should see findings such as the unused variable `x`, along with the affected location and suggested fix.

![Issue detected by SonarQube](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/540a69c4-510c-484a-a6e6-12eb21bd1705.png)

![Issue location and suggested fix](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/3656744c-a775-4a18-aa09-78dc4ba3f6b5.png)

## Summary

Docker makes it possible to run a first static analysis without creating complex configuration files. For CI, you can run the same Scanner command from a CI job.

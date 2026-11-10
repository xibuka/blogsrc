---
title: "Hello World！初めてのコードスキャンを実行してみよう"
date: 2025-12-02T23:49:19+09:00
draft: false
tags:
- SonarQube
- SonarScanner
- codesmell
- SAST
- CodeScanning
---

静的解析をCI/CDへ組み込む前に、まずローカルで動かしてみたい方向けの入門です。[Qiitaの記事](https://qiita.com/xibuka/items/42a93ae2b401d1296052)をもとに、DockerでSonarQube Serverを起動し、サンプルコードをSonarScanner CLIで解析します。

## 今回のゴールと準備

ソースコードをスキャンし、SonarQubeの画面でバグやCode Smellを確認します。Docker DesktopまたはDocker Engineと、次のPythonファイルを用意してください。

```python
def hello():
    print("Hello World")
    x = 10  # unused variable

hello()
```

## SonarQube Serverを起動

```bash
docker run -d --name sonarqube -p 9000:9000 sonarqube:community
```

ブラウザーで `http://localhost:9000` を開き、初期ユーザー名とパスワード `admin` / `admin` でログインします。初回ログイン後、パスワードを変更します。

![SonarQubeの初期ログイン画面](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/b600c4f3-bb06-4146-869d-9efe61038501.png)

## プロジェクト、Token、URLを準備

画面で [Create a local project] を選び、表示名 `hello-world` のプロジェクトを作成します。続いて My Account > Security でTokenを作成し、`scanner-cli` などの名前を付けます。生成されたTokenは画面を閉じる前にコピーしてください。

![ローカルプロジェクトの作成を開始](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/a13aa65e-7eb3-4ac3-9412-cb053cc0f342.png)

![プロジェクト表示名の入力](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/1e1d234a-d9ae-4b4f-a4fe-720da301952c.png)

![プロジェクト設定の確認](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/f08b92e0-bdf9-45a3-b58f-eec9e5879da9.png)

![SonarQube Tokenの生成](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/e89254ee-85df-46d3-a0fb-bc15614a2c2b.png)

Docker Desktop（Windows/Mac）からホストへ接続するURLは `http://host.docker.internal:9000` です。Linuxでは `http://localhost:9000` またはコンテナーIPを使用します。

## SonarScanner CLIでスキャン

`main.py` があるディレクトリで、Tokenを置き換えて実行します。

```bash
docker run --rm \
  -e SONAR_HOST_URL="http://host.docker.internal:9000" \
  -e SONAR_TOKEN="<your-token>" \
  -v "$(pwd):/usr/src" \
  sonarsource/sonar-scanner-cli \
  -Dsonar.projectKey=hello-world
```

`--rm` はスキャン後にScannerコンテナーを削除し、`-v` は現在のソースディレクトリをコンテナー内の `/usr/src` にマウントします。ログの最後に `EXECUTION SUCCESS` が出れば解析成功です。

## 結果を確認

SonarQubeの `http://localhost:9000/dashboard?id=hello-world` を再読み込みし、Issuesを開きます。未使用変数 `x` に対する指摘などが表示され、問題の場所や修正案を確認できます。

![SonarQubeで検出されたIssue](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/540a69c4-510c-484a-a6e6-12eb21bd1705.png)

![Issueの場所と修正案](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/2679136/3656744c-a775-4a18-aa09-78dc4ba3f6b5.png)

## まとめ

Dockerを使えば、複雑な設定ファイルを作らずに最初の静的解析を試せます。CIへ組み込む場合も、基本的には同じScannerコマンドをCIジョブから実行します。

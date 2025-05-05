---
title: CentOS7/RHEL7におけるsystemd入門ガイド
date: 2017-09-11 10:19:16
tags:
- Linux
- Systemd
---

## systemdの紹介

CentOS 7やRHEL 7以前では、System Vがシステムコントローラーとして使われていました。
システムコントローラーは、すべてのプロセスやサービス、起動タスクを管理できます。
System Vはスクリプトでタスクを管理するため、パフォーマンス上の問題があり、
タスクを直列でしか起動できず、システムの起動が遅くなります。

CentOS 7からは、systemdが新しいシステムコントローラーとなりました。
最大の変化は、タスクを並列で起動できるようになり、起動速度が向上したことです。
また、systemdのPIDは1であり、システム内のすべてのプロセスを管理しています！

この記事では、systemdによる「サービス」「起動タスク」「ログ管理」について紹介します。

## サービスの状態確認

### システム内のすべてのサービスを確認

```bash
systemctl list-unit-files --type=service
```

`PageUp`や`PageDown`で上下に移動し、`q`で終了します。

### 実行中のすべてのサービスを確認

```bash
systemctl  list-units --type=service
```

サービス名の前に大きな点（●）がある場合、そのサービスに問題があります。

### OS起動時に自動起動するサービスを確認

```bash
systemctl list-unit-files --type=service |  grep enabled
```

### サービスの詳細情報を確認

```bash
systemctl status <サービス名>
```

出力には、稼働状況、PID、サービスのパス、最新10件のログが含まれます。

```bash
systemctl status rsyslog
● rsyslog.service - System Logging Service
   Loaded: loaded (/usr/lib/systemd/system/rsyslog.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2017-09-11 08:42:46 JST; 1h 57min ago
     Docs: man:rsyslogd(8)
           http://www.rsyslog.com/doc/
 Main PID: 1417 (rsyslogd)
    Tasks: 3 (limit: 4915)
   CGroup: /system.slice/rsyslog.service
           └─1417 /usr/sbin/rsyslogd -n

Sep 11 08:42:43 diablo systemd[1]: Starting System Logging Service...
Sep 11 08:42:46 diablo rsyslogd[1417]:  [origin software="rsyslogd" swVersion="8.27.0" x-pid="1417" x-info="http://www.rsyslog.com"] start
Sep 11 08:42:46 diablo systemd[1]: Started System Logging Service.
Sep 11 09:36:02 diablo rsyslogd[1417]:  [origin software="rsyslogd" swVersion="8.27.0" x-pid="1417" x-info="http://www.rsyslog.com"] rsyslogd was HUPed
```

### 異常終了したサービスを確認

```bash
systemctl list-units --type=service --state=failed
```

### システムの起動時間を確認

```bash
systemd-analyze
Startup finished in 1.858s (kernel) + 3.654s (initrd) + 29.878s (userspace) = 35.392s
```

### サービスごとの起動時間を確認

```bash
systemd-analyze blame | grep .service
```

## サービスの管理

### サービスの起動

```bash
systemctl start <サービス名>
```

### サービスの停止

```bash
systemctl stop <サービス名>
```

### サービスの再起動

```bash
systemctl restart <サービス名>
```

### サービス設定のリロード

```bash
systemctl reload <サービス名>
```

サービスを再起動できないが設定を変更したい場合、reloadが有効です。

### OS起動時にサービスを自動起動する設定

```bash
systemctl enable <サービス名>
```

### OS起動時にサービスを自動起動しない設定

```bash
systemctl disable <サービス名>
```

### サービスのマスク

サービスをマスクすると、他のサービスや`start`や`restart`コマンドで起動できなくなります。

```bash
systemctl mask <サービス名>
```

### サービスのアンマスク

既にマスクされたサービスのマスクを解除します。

```bash
systemctl unmask <サービス名>
```

### サービスユニット全体のリロード

サービスユニットを追加・削除した際に実行します。

```bash
systemctl daemon-reload
```

## シンプルなサービスユニットファイルの作成

### ユニットファイルのパス

ユニットファイルを作成し、`/etc/systemd/system`に配置します。

### ユニットファイルの例

```conf
[Unit]
Description=<サービスの説明>
After=<どのサービスの後に起動するか（任意）>

[Service]
Type=forking
ExecStart=<実行コマンドのパス>
ExecReload=<設定ファイルのリロードコマンド（任意）>
KillSignal=SIGTERM
KillMode=mixed

[Install]
WantedBy=multi-user.target
```

新しいサービスユニットファイルを作成した後は`daemon-reload`を実行してください。

## Targetとランレベル

### デフォルトのランレベルを確認

```bash
systemctl get-default
```

### デフォルトのランレベルを設定

```bash
systemctl set-default <ターゲット名>
```

### ランレベルを変更

```bash
systemctl isolate <ターゲット名>
```

## ログの管理

## 最新の起動からのログを確認

```bash
journalctl -e -f
```

## ユニット（サービス）のログを確認

```bash
journalctl -e -f -u <ユニット名>
```

## 指定した期間のログを確認

```bash
journalctl --since="yyyy-MM-dd hh:mm:ss" --until="yyyy-MM-dd hh:mm:ss"
```

## ログのディスク使用量を確認

```bash
journalctl --disk-usage
```

## ログの最大ディスク使用量を変更

`/etc/systemd/journald.conf`の`SystemMaxUse=..`のコメントを外し、値を設定します。

```bash
SystemMaxUse=50M
```

その後、journaldサービスを再起動します。

```bash
systemctl restart systemd-journald.service
```

## 参考文献

- CentOS 7 Systemd 入門 ，作者: 余泽楠 [https://zhuanlan.zhihu.com/p/29217941](https://zhuanlan.zhihu.com/p/29217941)

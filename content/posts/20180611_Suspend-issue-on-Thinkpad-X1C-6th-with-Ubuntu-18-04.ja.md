---
title: Thinkpad X1C 6thでのUbuntu 18.04のサスペンド問題
date: 2018-06-11 15:38:10
tags:
- Ubuntu
- ThinkPad
---

## デフォルトでS3サスペンドがサポートされていない

Ubuntu 18.04を使用していると、Thinkpad X1 Carbonでサスペンドに問題が発生します。蓋を閉じても正しくサスペンドされず、電力消費が続き、ノートPCが熱くなります。

原因は、第6世代X1 CarbonがS0i3（Windows Modern Standbyとしても知られる）をサポートしている一方で、S3スリープ状態をサポートしていないことです。

## S0i3スリープのサポート

調査の結果、以下の手順で回避策が見つかりました：

1. カーネルパラメータに以下を追加してS0i3スリープを有効化
   これにより、蓋の開閉によるウェイクアップ/レジュームが無効化されます。

   ```conf
   acpi.ec_no_wakeup=1
   ```

1. BIOS設定でThunderbolt BIOS Assist Modeを有効化
   `Config -> Thunderbolt BIOS Assist Mode - "Enabled"` に設定します。

1. SDカードリーダーを無効化

この問題の詳細は以下を参照してください：

[X1 Carbon Gen 6 cannot enter deep sleep (S3 state aka Suspend-to-RAM) on Linux](https://forums.lenovo.com/t5/Linux-Discussion/X1-Carbon-Gen-6-cannot-enter-deep-sleep-S3-state-aka-Suspend-to/td-p/3998182)
[Suspend issues](https://wiki.archlinux.org/index.php/Lenovo_ThinkPad_X1_Carbon_(Gen_6)#Suspend_issues)
[X1 Carbon 6th gen S0i3 sleep broken](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1756105)

この回避策は後日テストし、結果を更新します。

もう一つの回避策が[https://delta-xi.net/#056](https://delta-xi.net/#056)にありますが、こちらは未検証です。

## テスト結果

8時間以上スリープさせたところ、バッテリーは99%から91%までしか減らず、温度も低いままでした。この回避策は有効だと思います。

---
title: Thinkpad X1C 6代在 Ubuntu 18.04 下的挂起（休眠）问题
date: 2018-06-11 15:38:10
tags:
- Ubuntu
- ThinkPad
---

## 默认不支持 S3 挂起

在 Thinkpad X1 Carbon 上使用 Ubuntu 18.04 时，挂起（休眠）会有问题。合上盖子后挂起无法正常工作，笔记本依然持续耗电并发热。

根本原因是第六代 X1 Carbon 支持 S0i3（也称为 Windows Modern Standby），但不支持 S3 睡眠状态。

## S0i3 睡眠支持

经过一些研究，可以通过以下方法规避：

1. 添加如下内核参数以启用 S0i3 睡眠支持
   这会禁用通过合盖唤醒/恢复

   ```conf
   acpi.ec_no_wakeup=1
   ```

1. 在 BIOS 设置中启用 Thunderbolt BIOS Assist Mode
   路径为 `Config -> Thunderbolt BIOS Assist Mode - 设为 "Enabled"`

1. 禁用 SD 卡读卡器

关于此问题的更多细节可参考：

[X1 Carbon Gen 6 cannot enter deep sleep (S3 state aka Suspend-to-RAM) on Linux](https://forums.lenovo.com/t5/Linux-Discussion/X1-Carbon-Gen-6-cannot-enter-deep-sleep-S3-state-aka-Suspend-to/td-p/3998182)
[Suspend issues](https://wiki.archlinux.org/index.php/Lenovo_ThinkPad_X1_Carbon_(Gen_6)#Suspend_issues)
[X1 Carbon 6th gen S0i3 sleep broken](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1756105)

我会稍后测试这个方法并更新结果。

还有一个方案见 [https://delta-xi.net/#056](https://delta-xi.net/#056)，但我尚未测试。

## 测试结果

睡眠超过8小时，电量从99%降到91%，我认为表现不错。温度也很低，所以这个方法是有效的。

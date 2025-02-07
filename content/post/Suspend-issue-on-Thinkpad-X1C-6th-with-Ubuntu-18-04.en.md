---
title: Suspend issue on Thinkpad X1C 6th with Ubuntu 18.04
date: 2018-06-11 15:38:10
tags:
- Ubuntu
- ThinkPad
---

# S3 Suspend not supported by default
There is an issue about suspend on Thinkpad X1 Carbon when using Ubuntu 18.04.
When you close the lid suspend does not works well. It will continue cose some
power and get you laptop hot.

The root cause is the 6th gen X1 Carbon supports S0i3(Which is also known as
Windows Modern Standby) but does not support the S3 sleep state.

# S0i3 sleep support

After some researching, the workaround can be this:

1. add below kernel parameter to enable s0i3 sleep support
   This disables wakeup/resume via lid open
```
acpi.ec_no_wakeup=1
```

2. enable Thunderbolt BIOS Assist Mode in BIOS configure
   It is in `Config -> Thunderbolt BIOS Assist Mode - Set to "Enabled"`

3. disable SD card reader

More details about this issue can be found at

[X1 Carbon Gen 6 cannot enter deep sleep (S3 state aka Suspend-to-RAM) on Linux](https://forums.lenovo.com/t5/Linux-Discussion/X1-Carbon-Gen-6-cannot-enter-deep-sleep-S3-state-aka-Suspend-to/td-p/3998182)
[Suspend issues](https://wiki.archlinux.org/index.php/Lenovo_ThinkPad_X1_Carbon_(Gen_6)#Suspend_issues)
[X1 Carbon 6th gen S0i3 sleep broken](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1756105)

I will test this work around later and update result.

Another workaround is at https://delta-xi.net/#056, but I haven't test for it.


# Test Update:

Over 8 hours sleep, battery only costed from 99% to 91%, which I think is OK.
Also the temperature is low, so I think the workaround is useful.

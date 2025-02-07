---
title: connect to wifi in Linux via nmcli command
date: 2019-08-17 00:55:53
tags:
- Linux
---

I will use `nmcli` to do this task.

First you need to install `network-manager` package, and start the Daemon

```
$ sudo apt install network-manager
$ sudo systemctl start NetworkManager
```

Then let's check the network interface status by below command

```
$ nmcli dev status
DEVICE          TYPE      STATE         CONNECTION
wlp2s0          wifi      connected     xibuka-wifi-5G
enp0s31f6       ethernet  connected     netplan-enp0s31f6
p2p-dev-wlp2s0  wifi-p2p  disconnected  --
eth0            ethernet  unavailable   --
lo              loopback  unmanaged     --
```

Next step is to check the available Wifi access points.

```
$ nmcli dev wifi list 
SSID            MODE   CHAN  RATE        SIGNAL  BARS  SECURITY  
aterm-55ebc5-g  Infra  11    405 Mbit/s  77      ▂▄▆_  WPA1 WPA2 
xibuka-wifi-2G  Infra  11    405 Mbit/s  77      ▂▄▆_  WPA1 WPA2 
xibuka-wifi-5G  Infra  36    405 Mbit/s  63      ▂▄▆_  WPA1 WPA2 
aterm-55ebc5-a  Infra  36    405 Mbit/s  54      ▂▄__  WPA1 WPA2 
HG8045-0D9B-bg  Infra  8     195 Mbit/s  49      ▂▄__  WPA1 WPA2 
HG8045-0D9B-a   Infra  44    405 Mbit/s  35      ▂▄__  WPA1 WPA2 
HG8045-A39A-a   Infra  108   405 Mbit/s  35      ▂▄__  WPA1 WPA2 
MNG6300-F560-G  Infra  11    130 Mbit/s  30      ▂___  WPA1 WPA2 
```

If you can not see the SSID you want to use, you can do a re-scan by below
command

```
nmcli dev wifi rescan
```

OK, let's try to connect to Wifi using below nmcli command

```
$ sudo nmcli dev wifi connect xibuka-wifi-5G password 'xxxxxxxxxx'
Device 'wlp2s0' successfully activated with 'f1cc419e-7b51-4d99-8cff-2894dc054f19'.
```

Or you can use `--ask` option to input your password interactively and don't
display it. 

```
$ sudo nmcli --ask dev wifi connect xibuka-wifi-5G 
Password:
Device 'wlp2s0' successfully activated with 'f1cc419e-7b51-4d99-8cff-2894dc054f19'.
```

Delete the established connections

```
sudo nmcli con del xibuka-wifi-5G
```

That's all! Hope this help you.

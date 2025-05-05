---
title: 在 Linux 下用 nmcli 命令连接 Wi-Fi
date: 2019-08-17 00:55:53
tags:
- Linux
---

这里用 `nmcli` 来完成这个任务。

首先需要安装 `network-manager` 包，并启动 Daemon。

```sh
sudo apt install network-manager
sudo systemctl start NetworkManager
```

然后用下面的命令查看网络接口状态：

```sh
$ nmcli dev status
DEVICE          TYPE      STATE         CONNECTION
wlp2s0          wifi      connected     xibuka-wifi-5G
enp0s31f6       ethernet  connected     netplan-enp0s31f6
p2p-dev-wlp2s0  wifi-p2p  disconnected  --
eth0            ethernet  unavailable   --
lo              loopback  unmanaged     --
```

接下来查看可用的 Wi-Fi 热点。

```sh
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

如果没有看到你想用的 SSID，可以用下面的命令重新扫描：

```sh
nmcli dev wifi rescan
```

现在用下面的 nmcli 命令连接 Wi-Fi：

```sh
$ sudo nmcli dev wifi connect xibuka-wifi-5G password 'xxxxxxxxxx'
Device 'wlp2s0' successfully activated with 'f1cc419e-7b51-4d99-8cff-2894dc054f19'.
```

也可以用 `--ask` 选项交互式输入密码，这样不会显示出来。

```sh
$ sudo nmcli --ask dev wifi connect xibuka-wifi-5G 
Password:
Device 'wlp2s0' successfully activated with 'f1cc419e-7b51-4d99-8cff-2894dc054f19'.
```

删除已建立的连接：

```sh
sudo nmcli con del xibuka-wifi-5G
```

就这些！希望对你有帮助。

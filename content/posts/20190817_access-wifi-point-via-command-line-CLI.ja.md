---
title: nmcliコマンドでLinuxからWi-Fiに接続する
date: 2019-08-17 00:55:53
tags:
- Linux
---

この作業には `nmcli` を使います。

まず `network-manager` パッケージをインストールし、デーモンを起動します。

```sh
sudo apt install network-manager
sudo systemctl start NetworkManager
```

次に、以下のコマンドでネットワークインターフェースの状態を確認します。

```sh
$ nmcli dev status
DEVICE          TYPE      STATE         CONNECTION
wlp2s0          wifi      connected     xibuka-wifi-5G
enp0s31f6       ethernet  connected     netplan-enp0s31f6
p2p-dev-wlp2s0  wifi-p2p  disconnected  --
eth0            ethernet  unavailable   --
lo              loopback  unmanaged     --
```

次に、利用可能なWi-Fiアクセスポイントを確認します。

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

目的のSSIDが表示されない場合は、以下のコマンドで再スキャンできます。

```sh
nmcli dev wifi rescan
```

では、以下のnmcliコマンドでWi-Fiに接続してみましょう。

```sh
$ sudo nmcli dev wifi connect xibuka-wifi-5G password 'xxxxxxxxxx'
Device 'wlp2s0' successfully activated with 'f1cc419e-7b51-4d99-8cff-2894dc054f19'.
```

または、`--ask` オプションを使えばパスワードを対話的に入力でき、表示されません。

```sh
$ sudo nmcli --ask dev wifi connect xibuka-wifi-5G 
Password:
Device 'wlp2s0' successfully activated with 'f1cc419e-7b51-4d99-8cff-2894dc054f19'.
```

作成済みの接続を削除するには

```sh
sudo nmcli con del xibuka-wifi-5G
```

以上です！お役に立てれば幸いです。

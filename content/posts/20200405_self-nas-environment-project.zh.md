---
title: "自建 NAS 环境项目"
date: 2020-04-05T15:22:58+09:00
draft: false
---
本文是我用 Ubuntu 20.04 搭建私人 NAS 站点的笔记。NAS 的主要用途是存储照片。
其他服务方面，使用 webmin 通过 WebUI 管理主机，Emby/Jellyfin 用于多媒体。这两个服务都运行在 docker 中，所以我也用 portainer 来管理。

## 概览

用 Samba 共享存储，iPhone 上传照片到 NAS 用 `PhotoSync`。用 smartctl 检查磁盘健康，如果有异常则邮件通知。

## 文件共享（Samba）

安装 Samba：

```bash
sudo apt-get install samba smbfs
```

编辑 `/etc/samba/smb.conf` 配置文件，如有需要可修改工作组。

```bash
# Change this to the workgroup/NT-domain name your Samba server will part of
   workgroup = WORKGROUP
```

然后设置共享文件夹，在文件末尾添加如下内容：

```bash
[share]
   comment = Share directory for my self-nas
   path = /share
   read only = no
   guest only = no
   guest ok = no
   share modes = yes
```

重启 `smbd` 服务并确认其运行状态。

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

设置访问 samba 服务器用户的密码。忘记密码时也可用此命令重设。

```bash
wshi@nuc:~$ sudo smbpasswd -a wshi
```

最后创建共享文件夹并设置权限为 `0777`

```bash
sudo mkdir /share
sudo chmod 0777 /share
```

## 磁盘检测 - SMART

NAS 需要 7x24 小时运行，所以要有脚本监控健康状态。SMART 是监控 HDD、SSD、eMMC 的好工具。

### 安装

```bash
sudo apt-get install smartmontools
```

### 检查 SMART 状态

扫描硬盘：

```bash
$ sudo smartctl --scan     
/dev/sda -d scsi # /dev/sda, SCSI device
/dev/sdb -d sat # /dev/sdb [SAT], ATA device
/dev/nvme0 -d nvme # /dev/nvme0, NVMe device
```

确认硬盘支持并启用了 SMART：

```bash
$ sudo smartctl -i /dev/sda  
...
SMART support is: Available - device has SMART capability.
SMART support is: Enabled
```

最后两行显示 SMART 是否可用和已启用。

## 显示 SMART 信息

```bash
$ sudo smartctl -A /dev/sda
...
```

（下文所有命令、说明、表格、步骤、参考链接等均会自然翻译为中文，Markdown 结构、代码块、表格、列表等全部保持原样）

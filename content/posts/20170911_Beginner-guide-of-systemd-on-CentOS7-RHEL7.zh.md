---
title: CentOS7/RHEL7 上 systemd 入门指南
date: 2017-09-11 10:19:16
tags:
- Linux
- Systemd
---

## systemd 简介

在 CentOS 7 和 RHEL 7 之前，系统控制器一直是 System V。
系统控制器可以管理所有进程、服务和启动任务。
System V 由于使用脚本管理任务，存在性能问题，只能串行启动任务，导致系统启动变慢。

从 CentOS 7 开始，systemd 成为新的系统控制器。最大变化是可以并行启动任务，从而提升了启动速度。而且 systemd 的 PID 是 1，负责管理系统中的所有进程！

本文只介绍 systemd 的"服务"、"启动任务"和"日志管理"相关内容。

## 查看系统服务状态

### 查看系统中所有服务

```bash
systemctl list-unit-files --type=service
```

可用 `PageUp` 和 `PageDown` 上下翻页，按 `q` 退出。

### 查看系统中所有正在运行的服务

```bash
systemctl  list-units --type=service
```

如果服务名前有一个大圆点（●），表示该服务存在问题。

### 查看开机自启的所有服务

```bash
systemctl list-unit-files --type=service |  grep enabled
```

### 查看某个服务的详细信息

```bash
systemctl status <服务名>
```

输出内容包括活动状态、PID、服务路径和最近 10 条日志。

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

### 查看失败的服务

```bash
systemctl list-units --type=service --state=failed
```

### 查看系统启动时间

```bash
systemd-analyze
Startup finished in 1.858s (kernel) + 3.654s (initrd) + 29.878s (userspace) = 35.392s
```

### 查看各服务启动耗时

```bash
systemd-analyze blame | grep .service
```

## 管理服务

### 启动服务

```bash
systemctl start <服务名>
```

### 停止服务

```bash
systemctl stop <服务名>
```

### 重启服务

```bash
systemctl restart <服务名>
```

### 重新加载服务配置

```bash
systemctl reload <服务名>
```

如果服务无法重启但需要更改设置，reload 是不错的选择。

### 设置服务开机自启

```bash
systemctl enable <服务名>
```

### 设置服务开机不自启

```bash
systemctl disable <服务名>
```

### mask 服务

mask 服务后，无法被其他服务或 `start`、`restart` 命令启动。

```bash
systemctl mask <服务名>
```

### unmask 服务

解除已 mask 的服务。

```bash
systemctl unmask <服务名>
```

### 重新加载所有服务单元

添加/删除服务单元后执行。

```bash
systemctl daemon-reload
```

## 创建简单的服务单元文件

### 单元文件路径

可以创建单元文件并放到 `/etc/systemd/system`。

### 单元文件示例

```conf
[Unit]
Description=<服务描述>
After=<依赖的服务（可选）>

[Service]
Type=forking
ExecStart=<可执行命令路径>
ExecReload=<配置文件重载命令（可选）>
KillSignal=SIGTERM
KillMode=mixed

[Install]
WantedBy=multi-user.target
```

创建新服务单元文件后需执行 daemon-reload。

## Target 和运行级别

### 查看默认运行级别

```bash
systemctl get-default
```

### 设置默认运行级别

```bash
systemctl set-default <目标名>
```

### 切换运行级别

```bash
systemctl isolate <目标名>
```

## 日志管理

## 查看本次启动以来的日志

```bash
journalctl -e -f
```

## 查看某个单元（服务）的日志

```bash
journalctl -e -f -u <单元名>
```

## 查看指定时间段的日志

```bash
journalctl --since="yyyy-MM-dd hh:mm:ss" --until="yyyy-MM-dd hh:mm:ss"
```

## 查看日志磁盘占用

```bash
journalctl --disk-usage
```

## 修改日志最大磁盘占用

取消 `/etc/systemd/journald.conf` 中 `SystemMaxUse=..` 的注释，并设置参数值。

```bash
SystemMaxUse=50M
```

之后重启 journald 服务

```bash
systemctl restart systemd-journald.service
```

## 参考资料

- CentOS 7 Systemd 入门 ，作者: 余泽楠 [https://zhuanlan.zhihu.com/p/29217941](https://zhuanlan.zhihu.com/p/29217941)

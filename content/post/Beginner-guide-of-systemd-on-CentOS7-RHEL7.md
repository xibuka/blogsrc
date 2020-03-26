---
title: Beginner guide of systemd on CentOS7/RHEL7
date: 2017-09-11 10:19:16
tags:
- Linux
- Systemd
---

# Introduction of systemd
Before CentOS 7 and RHEL 7, System V was used to be the system controller.
The system controller can manage all processes, services, and start task.
System V has a performance problem as it is using script to manage the tasks.
So it can only start the task serially, which will slow down the startup of the
system.

From CentOS 7, the systemd become the new system controller. The biggest
change is it can start task parallel and will improve the startup speed. And as
the its PID is 1, the systemd is controlling every process in the system!

This article will only shows the information of "service", "start up task", and "log manage" by systemd.

# Check the Service status of the system

## Check all services in the system

```
systemctl  list-unit-files --type=service
```

<!-- more -->

`PageUp` and `PageDown` to go up and down, type `q` to quit.

## Check all running services in the system

```
systemctl  list-units --type=service
```
If there is a big point ● in front of a service, it means this service has some
problems.

## Check all services which will start when the OS boot

```
systemctl list-unit-files --type=service |  grep enabled
```

## Check the detail information of a service

```
systemctl status <name of service>
```

The output will contain the status of activity, PID, path of the service, and
the latest 10 logs.

```
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

## Check the services which got failed

```
systemctl list-units --type=service --state=failed
```

## Check the time of system start up

```
systemd-analyze
Startup finished in 1.858s (kernel) + 3.654s (initrd) + 29.878s (userspace) = 35.392s
```

## Check the time of system start up by service

```
systemd-analyze blame | grep .service
```

# Manage the service

## Start a service

```
systemctl start <service name>
```

## Stop a service

```
systemctl stop <service name>
```

## Restart a service

```
systemctl restart <service name>
```

## Reload the configuration of a service

```
systemctl reload <service name>
```
If the service can't be restart but need to change the settings, reload is a
good choice.


## Set the service to start when OS boot

```
systemctl enable <service name>
```


## Set the service NOT to start when OS boot

```
systemctl disable <service name>
```

## mask a service  
Mask a service to make it can't be started by other service nor `start`
`restart` command.

```
systemctl mask <service name>
```

## unmask a service  
Unmask a service which has already been masked.

```
systemctl unmask <service name>
```

## reload all the service units
Do this when you add/remove service units.

```
systemctl daemon-reload
```

# Create a simple service unit file

## Path of the unit file
When can create a unit file an put it into `/etc/systemd/system`.

## An example of unit file

```
[Unit]
Description=<the description of the service>
After=<start after which service(optional)>

[Service]
Type=forking
ExecStart=<path to an executable command>
ExecReload=<reload command of the configuration file(optional)>
KillSignal=SIGTERM
KillMode=mixed

[Install]
WantedBy=multi-user.target
```

Run `daemon-reload` after create a new service unit file.

# Target and runlevel

## check the default runlevel

```
systemctl get-default
```

## set the default runlevel

```
systemctl set-default <target name>
```

## change the runlevel

```
systemctl isolate <target name>
```

# Manage logs

# Check the logs from the latest boot

```
journalctl -e -f
```

# Check the logs of a unit(service)

```
journalctl -e -f -u <unit name>
```

# Check the logs between specify times

```
journalctl --since="yyyy-MM-dd hh:mm:ss" --until="yyyy-MM-dd hh:mm:ss"
```

# Check the disk usage of the logs

```
journalctl --disk-usage
```

# Change the max disk usage of the logs.

Uncomment of `SystemMaxUse=..` in `/etc/systemd/journald.conf`, and set value
to this parameter.

```
SystemMaxUse=50M
```

After this, restart journald service

```
systemctl restart systemd-journald.service
```

# refs
- CentOS 7 Systemd 入门 ，作者: 余泽楠 https://zhuanlan.zhihu.com/p/29217941 


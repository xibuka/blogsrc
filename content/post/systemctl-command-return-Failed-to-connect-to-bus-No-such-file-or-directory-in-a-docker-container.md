---
title: >-
  systemctl command return 'Failed to connect to bus: No such file or directory'
  in a docker container
date: 2017-09-05 10:30:55
tags:
- docker
- Linux
- Python
---

To enable and start a cron job and a httpd server in a docker container, I
tried ` systemctl ` command but get an error output like this

```
[root@5f1f0a5cde43 app]# systemctl status crond    
Failed to connect to bus: No such file or directory
[root@5f1f0a5cde43 app]# systemctl status httpd    
Failed to connect to bus: No such file or directory
```

Fix this issue by add `--privileged` parameter to `docker run ` command

```
# docker images
REPOSITORY                          TAG                 IMAGE ID            CREATED           SIZE
freshcase                           v0.5                55acda97e409        4 minutes ago       707 MB
# docker run --privileged -d freshcase
# docker container list
CONTAINER ID        IMAGE                      COMMAND                  CREATED             STATUS              PORTS               NAMES     
81fbd5eb01cb        freshcase:v0.5             "/usr/sbin/init"         3 minutes ago       Up 3 minutes        80/tcp              lucid_wing

```

<!-- more -->

Then you can login to the container and use systemctl command as well

```
# docker exec -ti 81 bash
[root@81fbd5eb01cb app]# systemctl status httpd
● httpd.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled; vendor preset: disabled)
   Active: active (running) since Tue 2017-09-05 01:50:30 UTC; 4min 25s ago
     Docs: man:httpd.service(8)
 Main PID: 31 (httpd)
   Status: "Total requests: 0; Idle/Busy workers 100/0;Requests/sec: 0; Bytes served/sec:   0 B/sec"
    Tasks: 47 (limit: 4915)
   CGroup: /system.slice/docker-81fbd5eb01cb3f527f651b1765a6155570b7dd562b29d807b8cac12f9ecc004a.scope/system.slice/httpd.service
           ├─31 /usr/sbin/httpd -DFOREGROUND
           ├─36 /usr/sbin/httpd -DFOREGROUND
           ├─37 /usr/sbin/httpd -DFOREGROUND
           ├─38 /usr/sbin/httpd -DFOREGROUND
           ├─42 /usr/sbin/httpd -DFOREGROUND
           └─53 /usr/sbin/httpd -DFOREGROUND

Sep 05 01:50:30 81fbd5eb01cb systemd[1]: Starting The Apache HTTP Server...
Sep 05 01:50:30 81fbd5eb01cb httpd[31]: AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 172.17.0.3. Set the 'S
erverName' directive globally to suppress this message
Sep 05 01:50:30 81fbd5eb01cb systemd[1]: Started The Apache HTTP Server.
[root@81fbd5eb01cb app]#
[root@81fbd5eb01cb app]# systemctl status crond
● crond.service - Command Scheduler
   Loaded: loaded (/usr/lib/systemd/system/crond.service; enabled; vendor preset: enabled)
   Active: active (running) since Tue 2017-09-05 01:50:30 UTC; 4min 53s ago
 Main PID: 35 (crond)
    Tasks: 1 (limit: 4915)
   CGroup: /system.slice/docker-81fbd5eb01cb3f527f651b1765a6155570b7dd562b29d807b8cac12f9ecc004a.scope/system.slice/crond.service
           └─35 /usr/sbin/crond -n

Sep 05 01:50:30 81fbd5eb01cb systemd[1]: Started Command Scheduler.
Sep 05 01:50:30 81fbd5eb01cb crond[35]: (CRON) INFO (Syslog will be used instead of sendmail.)
Sep 05 01:50:30 81fbd5eb01cb crond[35]: (CRON) INFO (RANDOM_DELAY will be scaled with factor 78% if used.)
Sep 05 01:50:30 81fbd5eb01cb crond[35]: (CRON) INFO (running with inotify support)
...<snip>
```

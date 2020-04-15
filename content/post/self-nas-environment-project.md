---
title: "Self Nas Environment Project"
date: 2020-04-05T15:22:58+09:00
draft: true
---

# Samba

Install Samba by following command

```
sudo apt-get install samba smbfs
```

Configure samba settings by opening `/etc/samba/smb.conf`

If needed, change your workgroup

```
# Change this to the workgroup/NT-domain name your Samba server will part of
   workgroup = WORKGROUP
```

Next is to set your share folders, input something like this at the end of the
file.

```
[share]
   comment = Share directory for my self-nas
   path = /share
   read only = no
   guest only = no
   guest ok = no
   share modes = yes
```

Restart `smbd` service and confirm the service is running.

```
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

Set the password of the user which you want to use to access the samba server.
You can use this command again if you forgot the password.
```
wshi@nuc:~$ sudo smbpasswd -a wshi
```

Finially, create the share folder and set the right permissions `0777`
```
$ sudo mkdir /share
$ sudo chmod 0777 /share
```

# Mail
## sendEmail(CLI)
The NAS system will be 24x7 running so we need some script to monitor its
health. If anything is not good it's necessary to inform me by sending a mail.
SendEmail is a lightweight, completely command line-based SMTP email delivery 
program. If you have the need to send email from a command prompt this tool is 
perfect.

Install SendEmail by following command
```
$ sudo apt install sendemail
```

OK, let's send a test mail by it.
```
$ sendEmail -f <FROM ADDRESS>@gmail.com \
            -s smtp.gmail.com:587 \
            -xu <USERNAME> \
            -xp <PASSWORD> \
            -t <TO ADDRESS>@gmail.com  \
            -u "test title" \
            -m "test contents"
Apr 06 14:33:24 nuc sendEmail[24438]: NOTICE => Authentication not supported by the remote SMTP server!
Apr 06 14:33:25 nuc sendEmail[24438]: ERROR => Received: 	530 5.7.0 Must issue a STARTTLS command first. mm18sm11195078pjb.39 - gsmtp
```

Oops, it failed with unsupported error. And looks related to tls.

Let's specify the tls supported and re-run the command.

```
$ sendEmail -f <FROM ADDRESS>@gmail.com \
            -s smtp.gmail.com:587 \
            -xu <USERNAME> \
            -xp <PASSWORD> \
            -t <TO ADDRESS>@gmail.com  \
            -u "test title" \ 
            -m "test contents" \
            -o tls=yes
Apr 06 15:16:10 nuc sendEmail[25354]: ERROR => No TLS support!  SendEmail can't load required libraries. (try installing Net::SSLeay and IO::Socket::SSL)
```

We got a different message, and the root cause is we need more libraries. There
are 2 packages we need to install.

```
$ sudo apt-get install libnet-ssleay-perl
$ sudo apt-get install libio-socket-ssl-perl
```

Re-run the command and we can send email from CLI. :-)

```
Apr 06 15:17:28 nuc sendEmail[25507]: Email was sent successfully!
```

# health check
## smartctl

# docker management
## portainer
There are a lot of docker image for a better NAS life, so let's install and
setup Portainer first.
Portainer gives you a detailed overview of your Docker environments and allows 
you to manage your containers, images, networks and volumes. 
Install protainer is easy as it can be deployed as a container. Use the
following command to deploy the Portainer Server.

```
$ docker volume create portainer_data
$ docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer
```

Please note the ` -v /var/run/docker.sock:/var/run/docker.sock` works in Linux
environment only.

If your container runs successfully, You can now login to `https://<SERVER IP
ADDR>:9000/` to access the protainer dashboard. First it will ask you a new 
password for admin user. Connect your local docker engine environment and you
can see something as follows.

![protainer_dashboard](/img/2020-04-06_11-38.png)

# multi-media
## Emby server

Emby is a media server designed to organize, play, and stream audio and video 
to a variety of devices.

The install is very easy, you can start a container to run Emby server. There
is a Installation Guide on ![dockerhub](https://hub.docker.com/r/emby/embyserver#installation)

First pull the latest image

```
docker pull emby/embyserver:latest
```

Then just launch a new container using the following command

```
docker run -d \
    --volume /path/to/programdata:/config \ # This is mandatory
    --volume /path/to/share1:/mnt/share1 \ # To mount a first share
    --volume /path/to/share2:/mnt/share2 \ # To mount a second share
    --device /dev/dri:/dev/dri \ # To mount all render nodes for VAAPI/NVDEC/NVENC
    --runtime=nvidia \ # To expose your NVIDIA GPU
    --publish 8096:8096 \ # To expose the HTTP port
    --publish 8920:8920 \ # To expose the HTTPS port
    --env UID=1000 \ # The UID to run emby as (default: 2)
    --env GID=100 \ # The GID to run emby as (default 2)
    --env GIDLIST=100 \ # A comma-separated list of additional GIDs to run emby as (default: 2)
    emby/embyserver:latest
```

Above one is from the offical guide, but you don't need to set all the options.
Some of the options are not necessary to change, if you ignore it the default
setting will work. Let me paste the command works for me.

```
$ sudo docker run -d  --volume /share/movie:/mnt/share1 \
                      --publish 8096:8096  \
                      --env UID=`id -u` \
                      --env GID=`id -g` \
                      emby/embyserver:latest
```

If your container runs successfully, You can now login to `https://<SERVER IP
ADDR>:8096/` to access the Emby site, and follow the guide to set your
environment. 

There is one important setting about the subtitles, you need to create a new
account at https://www.opensubtitles.org/, and set your username/password in
Emby. Then you should download subtitle in Emby, this is super helpful.

# Web control pannel
## webmin

Webmin is a web-based interface for system administration for Unix. Using any
modern web browser, you can setup user accounts, Apache, DNS, file sharing and
much more. Webmin removes the need to manually edit Unix configuration files
like /etc/passwd, and lets you manage a system from the console or remotely.
See the standard modules page for a list of all the functions built into
Webmin. 

The install of webmin is easy. First need to import the webmin GPG key and the
apt-repository. Then you can just install webmin via `apt` command.

```
$ wget -q http://www.webmin.com/jcameron-key.asc -O- | sudo apt-key add -
$ sudo add-apt-repository "deb [arch=amd64] http://download.webmin.com/download/repository sarge contrib"
$ sudo apt install webmin
```

After the install, a message will be displayed as follows. Access the URL with
the username and password in the host machine to login to the webUI.

```
Webmin install complete. You can now login to https://<SERVER IP ADDR>:10000/
as root with your root password, or as any user who can use sudo
to run commands as root.
```

The dashboard is like this
![dashboard](/img/2020-04-05_16-29.png)

Then you can check or modify contents/settings on the host machine.
For example, to check the files, click `Others->FIle Manager`.

![filemanager](/img/2020-04-05_16-35.png)

If your system is behind a UFW firewall, you may need to open the 10000 port
which is used by default to listen connections.

To alow traffic on port `10000` run the following command.

```
$ sudo ufw allow 10000/tcp
```

Refers to 

https://www.digitalocean.com/community/tutorials/how-to-install-webmin-on-ubuntu-18-04

https://linuxize.com/post/how-to-install-webmin-on-ubuntu-18-04/

---
title: Install Chrome Browser via yum in CentOS or Fedora or RHEL
date: 2017-07-14 09:29:58
tags:
- Linux
- RHEL
- yum
- CentOS
- Fedora
---

## Create a google yum repository

Create a file `/etc/yum.repos.d/google-chrome.repo` and add the following into it.

```conf
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
```

## Check the google repository

Run following command to check the repository is available.

```zsh
yum info google-chrome-stable
```

From the output you should find the lastest version of the package `google-chrome-stable`

```zsh
$ yum info google-chrome-stable
Fedora 26 - x86_64 - Updates                                                                                                                                  6.3 MB/s | 4.1 MB     00:00    
Fedora 26 - x86_64                                                                                                                                            7.5 MB/s |  53 MB     00:07    
google-chrome                                                                                                                                                  73 kB/s | 3.7 kB     00:00    
Last metadata expiration check: 0:00:00 ago on Fri 14 Jul 2017 09:25:33 AM JST.
Available Packages
Name         : google-chrome-stable
Version      : 59.0.3071.115
Release      : 1
Arch         : x86_64
Size         : 58 M
Source       : google-chrome-stable-59.0.3071.115-1.src.rpm
Repo         : google-chrome
Summary      : Google Chrome
URL          : https://chrome.google.com/
License      : Multiple, see https://chrome.google.com/
Description  : The web browser from Google
             : 
             : Google Chrome is a browser that combines a minimal design with sophisticated technology to make the web faster, safer, and easier.
```

## Install Chrome via yum

Let's install chrome browser using yum command as below, which will
automatically install all needed dependencies.

```zsh
yum install google-chrome-stable
google-chrome                                                                                                                                                  78 kB/s | 3.7 kB     00:00    
Last metadata expiration check: 0:00:00 ago on Fri 14 Jul 2017 09:25:41 AM JST.
Dependencies resolved.
==============================================================================================================================================================================================
 Package                                                  Arch                               Version                                          Repository                                 Size
==============================================================================================================================================================================================
Installing:
 google-chrome-stable                                     x86_64                             59.0.3071.115-1                                  google-chrome                              58 M
Installing dependencies:
 at                                                       x86_64                             3.1.20-3.fc26                                    fedora                                     77 k
 ed                                                       x86_64                             1.14.1-2.fc26                                    fedora                                     79 k
 esmtp                                                    x86_64                             1.2-6.fc26                                       fedora                                     56 k
<snip...>
 spax                                                     x86_64                             1.5.3-8.fc26                                     fedora                                    211 k
 systemtap-sdt-devel                                      x86_64                             3.1-5.fc26                                       fedora                                     71 k
 util-linux-user                                          x86_64                             2.30-1.fc26                                      updates                                    90 k
Installing weak dependencies:
 perl-Module-Runtime                                      noarch                             0.014-9.fc26                                     fedora                                     24 k

Transaction Summary
==============================================================================================================================================================================================
Install  126 Packages

Total download size: 71 M
Installed size: 265 M
Is this ok [y/N]: y
```

## Start Chrome

Start Chrome by below command, you can start it with a non-root user.

```zsh
google-chrome &
```

Enjory!

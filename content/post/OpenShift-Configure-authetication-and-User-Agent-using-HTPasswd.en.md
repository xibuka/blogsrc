---
title: OpenShift Configure authentication and User Agent using HTPasswd
date: 2017-07-12 14:43:47
tags:
- OpenShift
- Linux
---

As we Install the OpenShift by Ansible method, identity provider is set to *Deny all* by default, which will deny access from all users. To allow access for users, you must choose another identity provider and configure the *master configuration file*. By default, the *master configuration file* is located at */etc/origin/master/master-config.yaml*.
OpenShift has several identity providers which can help you to manager user authentication. I will use **HTPasswd** this time. You can find more information in
[Configuring Authentication and User Agent](https://docs.openshift.com/container-platform/3.5/install_config/configuring_authentication.html)

# Install package

The htpasswd utility is provided in httpd-tools package.

```
# yum install httpd-tools
```

# configure the master configuration file

```
oauthConfig:
  ...
  identityProviders:
  - name: my_htpasswd_provider 
    challenge: true 
    login: true 
    mappingMethod: claim 
    provider:
      apiVersion: v1
      kind: HTPasswdPasswordIdentityProvider
      file: /path/to/users.htpasswd 
```

Need to restart `atomic-openshift-master` to make the change to take effect.

```
# systemctl restart atomic-openshift-master
```

# Setup username and password

HTPasswd use a flat file to manager the username and the password, in which the
password is hashed. Run following command to create the file with *username*,
and it will ask you to input the password for *username*.

```
$ htpasswd -c </path/to/users.htpasswd> user1
New password:
Re-type new password:
Adding password for user user1
```

You can also include the password by adding the `-b` option

```
$ htpasswd -c -b user1 <password>
```

After add a user, you can use it to access OpenShift Container Platform.

## add/update an user

To add or update an username, run following command

```
$ htpasswd </path/to/users.htpasswd> <user_name>
```

## delete an user

To delete an username, run following command

```
$ htpasswd -D </path/to/users.htpasswd> <user_name>
```

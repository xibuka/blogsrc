---
title: OpenShift 使用 HTPasswd 配置认证和用户代理
date: 2017-07-12 14:43:47
tags:
- OpenShift
- Linux
---

使用 Ansible 方法安装 OpenShift 时，默认的身份提供者（identity provider）为 *Deny all*，即拒绝所有用户访问。要允许用户访问，必须选择其他身份提供者并配置 *master 配置文件*。默认的 *master 配置文件* 路径为 */etc/origin/master/master-config.yaml*。
OpenShift 提供多种身份提供者用于用户认证管理。本例使用 **HTPasswd**。更多信息见：[Configuring Authentication and User Agent](https://docs.openshift.com/container-platform/3.5/install_config/configuring_authentication.html)

## 安装软件包

htpasswd 工具包含在 httpd-tools 包中。

```bash
yum install httpd-tools
```

## 配置 master 配置文件

```yaml
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

需要重启 `atomic-openshift-master` 服务使配置生效。

```sh
systemctl restart atomic-openshift-master
```

## 设置用户名和密码

HTPasswd 使用一个平面文件管理用户名和密码（密码为哈希值）。运行如下命令创建文件并为 *username* 设置密码。

```sh
$ htpasswd -c </path/to/users.htpasswd> user1
New password:
Re-type new password:
Adding password for user user1
```

也可以用 `-b` 选项直接指定密码：

```sh
htpasswd -c -b user1 <password>
```

添加用户后，即可用该用户访问 OpenShift Container Platform。

## 添加/更新用户

添加或更新用户名，运行如下命令：

```sh
htpasswd </path/to/users.htpasswd> <user_name>
```

## 删除用户

删除用户名，运行如下命令：

```sh
htpasswd -D </path/to/users.htpasswd> <user_name>
```

---
title: Ansible 入門 - 紹介
date: 2018-04-09 15:15:32
tags:
- Linux
- Ansible
---

こちらの記事はではAnsibleを紹介するための文章で、元Red Hat社員のJingjing Shiが作成し、Wenhan Shiが日本語に翻訳しました。内容の校正はHideki SaitoとKento Yagisawaが協力しています。Ansibleの基礎知識から、実際の現場で利用できる実運用まで紹介しています。

本文内にあるすべてのansible playbookの例は、以下のgithubのURLから利用できる。
[https://github.com/ansible-book/ansible-first-book-examples](https://github.com/ansible-book/ansible-first-book-examples)
もし不備やコメントがありましたら、作者[shijingjing02@163.com](mailto:shijingjing02@163.com)または翻訳者[shibunkan@gmail.com](mailto:shibunkan@gmail.com) に連絡してください。

詳細の内容を下記三つに分けて説明します。

[Ansible 入門 - 紹介](http://wenhan.blog/2018/04/09/Getting-started-with-Ansible-JP-intro/)
[Ansible 入門 - 基本](http://wenhan.blog/2018/04/09/Getting-started-with-Ansible-JP-basic/)
[Ansible 入門 - 応用](http://wenhan.blog/2018/04/09/Getting-started-with-Ansible-JP-adv/)

本章では、Ansibleの基礎部分の紹介を説明する。

# Ansibleとは

## Ansibleとはなにか？

Ansibleは、複数のサーバを一括でコントロールする構成管理ツールである。コントロールできるサーバ対象はリモートの仮想マシンでも物理マシンでも問ローカルのサーバマシンも問題ない。



## Ansibleでなにができる？

Ansibleでは、SSHなどを利用し管理ノードからリモートノードへの通信を行う。理論上では、サーバ管理者がsshでサーバにログインした後できるすべてのことに対し、Ansibleも同じことができる。

例えば

* ファイルコピー
* パッケージインストール
* デーモンサービス起動
* その他

# アーキテクチャ

管理者ノードとリモートノードの間では、SSHプロトコルを利用して通信を行っている。そのため、Ansible環境を設定する時に、管理者ノードからリモートノードへSSHログインできることが必要である。ただし、SSHログインはパスワードレスに設定しなければいけない。詳細な設定方法は後ほど説明する。

## SSH接続

管理者ノードでAnsibleをインストールし、スクリプトの編集を行う。管理者ノードでAnsibleのコマンドやスクリプトを実行する時に、管理対象のサーバにSSHで接続する。管理対象のサーバの上にパッケージをインストールする必要がない。
![ansible ssh connection](/img/ansible/ansible_0.png)

## 多種類のサーバに対応

AnsibleはRedHat系、Debian系のLinuxと、Windows系のサーバを同時に管理することができる。管理者ノードはスクリプトを実行する時のみリモートサーバに接続するため、他の同期処理がない。そのため、通常の状態では、停電などの異常状態はAnsibleを影響しない。
![servers](/img/ansible/ansible_1.png)

## Ansible Towerのアーキテクチャ

### なぜAnsible Towerが必要なのか？

Ansible Towerは企業向けの有償ソフトウェアである。
前章のAnsible アーキテクチャとこれからのAnsibleのインストールでは、すべてのAnsibleでの管理対象となるサーバは、sshの公開鍵認証によるパスワードレスSSH接続を設定する必要がある。一般ユーザの場合、数台の仮想サーバやリモートサーバのみを管理するため特に問題ないが、企業ユーザに対し業務プロセスと安全性を確保しにくくなる。

* 1台のリモートサーバを追加する毎に、パスワードレスなSSH接続の設定を手動で行うことは非常に非効率的である。企業レベルのサーバが数百台、数千台規模になると、各サーバ管理者が自分の管理者ノードで全サーバに対しパスワードレスSSH接続の設定が必要となり、作業量は膨大になる。
* 管理者がパスワードレスSSH接続の為のssh keyを入手したり、他人にコピーしたりすると、本番環境に対し重大なセキュリティの問題になる。

### Ansible Towerでなにができるのか？

Ansible Towerは企業ユーザ向けに開発されている、集中管理や権限による制限、ジョブスケジューリング機能などを提供するソフトウェアである。このソフトウェアは管理者にWebUIやREST APIを提供し、Playbookの実行やワークフローテンプレートによる条件分岐などをサポートする。

* 管理者は、Ansible Tower上にサーバのssh keyを使用したりシェアしたりすることができるが、ssh keyの内容参照やコピーすることはできない。
* Ansible Towerでは、各管理者がシェアしているplaybookスクリプトを参照するとこができるため、重複する作業を減らすことができる。
* また、Ansible Towerは現在すべてのサーバでのplaybookの実行状況を集計/表示するため、状態の確認や統計もできる。

下記の図でAnsible Towerのアーキテクチャを示している。

![Ansible Tower](/img/ansible/ansible_2.png)

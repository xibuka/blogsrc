---
title: Ansible 入門 - 基本操作(チュートリアル)
date: 2018-04-09 15:25:32
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

本章では、簡単な例を使ってAnsibleの基本的な使い方を説明する。

1. インストール
1. 管理対象のサーバー（サーバリストの管理）
1. コマンドラインによるサーバー管理(Ad-hoc command)
1. スクリプトによるサーバー管理(スクリプト言語 Playbook)
1. モジュール

## インストール

ここでは Red Hat 系 Linux でのインストールを前提に解説にする。他のOSに関していAnsibleのWebページをご参照ください。

### 管理者ノード

#### Ansible パッケージをインストール

``` bash
# Redhat/CentOS Linuxの場合, epolリポジトリをインストールする必要がある。
# Fedoraの場合、デフォルトのリポジトリにAnsibleを含まれているため，直接インストールできる
sudo yum install epel-release
sudo yum install ansible -y
```

#### 管理者ノードからリモートノードの接続設定

SSH keyによる認証パスワードレス）方式を設定する。

```bash
# ssh key を生成
ssh-keygen
# リモートノードにssh keyをコピー
ssh-copy-id remoteuser@remoteserver
# リモートノードをknows_hostsに追加（ssh Keyの保存確認がなくなる）
ssh-keyscan remote_servers >> ~/.ssh/known_hosts
```

#### 設定確認

管理者ノードで下記コマンドを実行し、パスワードの入力とSSH keyの保存確認がなかったら設定完了。

```bash
ssh remoteuser@remoteserver
```

### リモートノード

Python 2.4以上が必要だが、通常はデフォルトでインストールされている。そのため、別途パッケージのインストールは必要ない。

## 管理対象のサーバー（サーバーリストの管理）

### サーバリスト（Host Inventory）とは

Host InventoryはAnsibleの設定ファイルであり、管理対象となるリモートノードの一覧をAnsibleに教える。
また、下記のように状況に応じてリモートノードのカテゴリ化もできる。
使い道によってカテゴリ化する：データベースノード、サービスノード。
ロケーションによってカテゴリ化する：中部データセンター、西部データセンター

### Host Inventoryファイル

デフォルトのファイルパス： `/etc/ansible/hosts`

他のファイルパスへ変更することもできる、詳細については後程紹介する。

例：

一番シンプルのhosts ファイル

```YAML
192.168.1.50
aserver.example.org
bserver.example.org
```

カテゴリを持つhosts ファイル

```YAML
mail.example.com

[webservers]
foo.example.com
bar.example.com

[dbservers]
one.example.com
two.example.com
three.example.com
```

## コマンドラインによるサーバー管理(Ad-hoc command)

Ansibleではコマンドラインツールを提供していて、オフィシャルドキュメントでは Ad-Hoc Commandsと名付けている。ansibleコマンドのフォーマットを以下に示す。

```bash
ansible <host-pattern> [options]
```

### Ansible コマンドができること

コマンドの構文の詳細を置いといて、"命令”モジュールの説明が終わったら構文の理解が深まりにいく。ここでは、下記のコマンドの例を通して、ansibleコマンドの役割を体感しましょう

#### 環境を確認する

ansible管理者ノードからユーザ bruce で各リモートノードをアクセスすることを確認する。

```bash
ansible all -m ping -u bruce
```

#### コマンド実行

現在bash ユーザと同名のユーザがすべてのリモートノードに対し"echo”コマンドを実行する。

```bash
ansible all -a "/bin/echo hello"
```

#### ファイルコピー

`/etc/hosts` ファイル を全リモートノードのweb グループにコピーし、コピー先は`/tmp/hosts`

```bash
ansible web -m copy -a "src=/etc/hosts dest=/tmp/hosts"
```

#### パッケージインストール

全リモートノードのweb グループのマシンにyum でacmeパッケージをインストール

```bash
ansible web -m yum -a "name=acme state=present"
```

#### ユーザ追加

```bash
ansible all -m user -a "name=foo password=<crypted password here>"
```

#### パッケージダウンロード

```bash
ansible web -m git -a "repo=git://foo.example.org/repo.git dest=/srv/myapp version=HEAD"
```

#### サービス起動

```bash
ansible web -m service -a "name=httpd state=started"
```

#### 並列実行

リブート命令を10並列で実行する。

```bash
ansible lb -a "/sbin/reboot" -f 10
```

#### リモートノード情報取得

```bash
ansible all -m setup
```

## スクリプトによるサーバー管理

重複な入力を避けるため、Ansibleをスクリプトの実行に対応する。AnsibleのスクリプトはPlaybookと読んで、YAML形式で、拡張子はymlである。Note: YAMLとJSONは似ていて、データを表示するフォーマットである。

### Playbookの実行方法

```bash
ansible-playbook deploy.yml
```

#### Playbookの例

Playbook deploy.ymlを通して、webグループのリモートサーバに対しapacheをデプロイする。ステップとしては

1. Apacheパッケージをインストール
1. 設定ファイルhttpdをコピーし、コピー完了後apacheサービスを再起動することを保証
1. デフォルトweb pageのindex.htmlをコピー
1. Apacheサービスを起動

このPlaybook deploy.yml 内では以下のキーワードを含まれている。

| キーワード  | 内容 | 備考 |
| --------- | ---- | ---- |
| hosts     | リモートノードのIP、またはグループ名、またはキーワードall | |
| remote_user | 実行ユーザ ||
| vars | 変数 ||
| tasks[^1]| Playbookのコア部分、処理内容actionを順番通りに実行する。各actionはansible moduleを利用する。 | action の構文：module: module_parameter=module_value。|
| handers | Playbookのイベントで、デフォルトでは実行されず、action内でトリガーの条件に満足したら実行する。複数のトリガー条件にマッチしても1回のみ実行する。||

[^1]よく利用するモジュールはyum, copy, templateなど。Ansibleの中のmodule は、bash の中のyum, copyの命令に似ている。詳細は後程紹介する

以下はdeploy.ymlの内容を示す。

```YAML
---
- hosts: web
  vars:
    http_port: 80
    max_clients: 200
  remote_user: root
  tasks:
  - name: ensure apache is at the latest version
    yum: pkg=httpd state=latest

  - name: Write the configuration file
    template: src=templates/httpd.conf.j2 dest=/etc/httpd/conf/httpd.conf
    notify:
    - restart apache

  - name: Write the default index.html file
    template: src=templates/index.html.j2 dest=/var/www/html/index.html

  - name: ensure apache is running
    service: name=httpd state=started
  handlers:
    - name: restart apache
      service: name=httpd state=restarted
```

YAMLが分からなかったら、上記deploy.ymlをJSON形式に変換することも可能だ。

```JSON
[
  {
    "hosts": "web",
    "vars": {
      "http_port": 80,
      "max_clients": 200
    },
    "remote_user": "root",
    "tasks": [
      {
        "name": "ensure apache is at the latest version",
        "yum": "pkg=httpd state=latest"
      },
      {
        "name": "Write the configuration file",
        "template": "src=templates/httpd.conf.j2 dest=/etc/httpd/conf/httpd.conf",
        "notify": [
          "restart apache"
        ]
      },
      {
        "name": "Write the default index.html file",
        "template": "src=templates/index.html.j2 dest=/var/www/html/index.html"
      },
      {
        "name": "ensure apache is running",
        "service": "name=httpd state=started"
      }
    ],
    "handlers": [
      {
        "name": "restart apache",
        "service": "name=httpd state=restarted"
      }
    ]
  }
]
```

JSON と YAMLをお互いに変換するオンラインツール：[http://www.json2yaml.com/](http://www.json2yaml.com/)

### Play vs. Playbook

Playbookは Ansibleで実行可能な YAMLファイルである。一般的な構文を以下の例に示す。

```YAML
---
- hosts: web
  remote_user: root
  tasks:
  - name: ensure apache is at the latest version
    yum: pkg=httpd state=latest
```

一つのPlaybookファイルの中で、二つのリモートノードグループに対しそれぞれ異る操作を存在することができる。例えば、webノードにhttpdパッケージのインストールと、lbノードにmysqlパッケージのインストール処理を一つのPlaybook ファイルに設定することができる。

```YAML
---
# apache をインストールのplay
- hosts: web
  remote_user: root
  tasks:
  - name: ensure apache is at the latest version
    yum: pkg=httpd state=latest

# mysql をインストールのplay
- hosts: lb
  remote_user: root
  tasks:
  - name: ensure mysqld is at the latest version
    yum: pkg=mariadb state=latest
```

上記の例では、一つのサーバに対する操作処理は、一つのPlayになる。一般的には一つのPlaybookでは一つのPlayしか実行しないため、その場合にはPlaybookとPlayは同じである。

## Ansibleのモジュール

### Ansibleのモジュールとは

Bashを利用する時、コマンドラインでもスクリプト内でも、cd, ls, copy, yumなどの命令を実行する必要がある。AnsibleのモジュールはAnsibleの命令であり、Ansibleのコマンドラインやスクリプト上にて実行されている。よく使うモジュールとしてyum, copy, templateなどがある。

Bashでのコマンドを利用するときに、さまざまなオプションが利用できて、このオプションはコマンドごとに定義されている。それと同じように、Ansibleのモジュールを実行する時に複数のオプションをつけることができて、各モジュールのオプションはモジュール内に定義されている。

モジュールの利用方法は以下のドキュメントを参照で
[http://docs.ansible.com/ansible/modules_by_category.html](http://docs.ansible.com/ansible/modules_by_category.html)

### コマンドラインにてAnsibleモジュールを利用

Ansible コマンドラインでは、以下の様にモジュールを利用できる。

```bash
  -m <モジュール名>

  -a モジュールのパラメータ
```

例えば

```bash
# module copyを利用し、管理者ノードの/etc/hostsをリモートノードの/tmp/hostsにコピー
ansible all -m copy -a "src=/etc/hosts dest=/tmp/hosts"
# module yumを利用しリモートノードweb上にhttpdパッケージをインストール
ansible web -m yum -a "name=httpd state=present"
```

### PlaybookにてAnsibleモジュールを利用

Playbookスクリプトでは、task内一つのactionは一つのモジュールを実行している。各actionに対し、

  : の前はモジュールの名前

  : の後ろはモジュールのパラメータ

```YAML
---
  tasks:
  - name: ensure apache is at the latest version
    yum: pkg=httpd state=latest
  - name: write the apache config file
    template: src=templates/httpd.conf.j2 dest=/etc/httpd/conf/httpd.conf
  - name: ensure apache is running
    service: name=httpd state=started
```

### Ansibleモジュールの特性

* Linuxのコマンドのように、Ansibleのモジュールはコマンドライン上で実行することもできるし、Playbook内に書いて実行することもできる。
* 各モジュールのパラメータや状態の判断は、このモジュールの仕様によって決められている。そのため、モジュールを利用する前に、このモジュールのドキュメントを参照することが必要である。
  * オンラインドキュメントの参照は：[http://docs.ansible.com/ansible/list_of_all_modules.html](http://docs.ansible.com/ansible/list_of_all_modules.html)
  * ansible-doc コマンドからモジュールの仕様が確認できる。
* Ansibleはよく利用するモジュールを多数公開していますが、APIを公開しているので、ユーザが自分のモジュールの開発もできる。AnsibleのモジュールはPythonで書かれている。

### よく使うAnsibleモジュールの紹介

Linuxを利用する時、コマンド命令が分からないとLinux 利用することはできない。これと同じようにAnsibleを利用するために基本のモジュールを理解することが大事である。

これからは普段よく使われているモジュールを紹介する。

* テスト＆確認用
  * ping:  リモートノードにpingして、正常に接続ができる場合は"pong”を返す。
  * debug: デバッグ用、情報を出力のみ、Linuxのecho コマンドに似ている。

* ファイル操作
  * copy: ローカルのファイルをリモートノードにコピー
  * template: ローカルのファイルをリモートノードにコピーし、変数を変更
  * file: ファイルのパーミッションや属性を設定

* システム操作
  * user: ユーザアカウント管理
  * yum: red hat 系Linuxのパッケージ管理
  * service: サービスの管理
  * firewalld: ファイアウォール内のサービスやポートの管理

* Shell命令実行
  * shell: リモートノード上shell命令を実行、$HOMEや"<”, ”>”, "|”と“&”などは利用可能
  * command: リモートノード上shell命令を実行、$HOMEや"<”, ”>”, "|”と“&”などは利用不可

#### ping

管理者ノードからリモートノードへの接続状態を確認するときに一番よく使われているモジュールである。ただShellのpingコマンドみたいにただリモートノードを"ping”するだけではなく、パスワードレスのSSHログインと、リモートノードのpythonのversionを確認し、両方問題なかったらpongを返す。

pingモジュールを使う時にパラメータが必要ない。リモートノードの接続状況を確認するためコマンドラインでの利用がplaybookの中より多くなっている。下記はコマンドラインでのpingモジュールの例を示す。

```bash
ansible servers -m ping
```

#### debug

Shellのechoコマンドに似ていて。メッセージを出力する。
msgパラメータに出力したいメッセージ内容を設定する。下の例では、システム情報をメッセージ内容に含めて出力している。Ansibleが実行する前にシステム情報を集めて定数にしているため、playbook内に定義しなくても利用できる。

```YAML
- debug:
    msg: "System \{\{ inventory_hostname \}\} has gateway \{\{ ansible_default_ipv4.gateway \}\}"
```

実行結果

```bash
TASK [debug] *******************************************************************
ok: [localhost] => {
    "msg": "System localhost has gateway 192.168.50.1"
}
```

出力したい情報をvar パラメータを定義し出力させることができる。情報はシステム情報でも、モジュール実行結果を取り込むことができ、キーワードregesterを用いて変数に設定する。
例えば、システム情報を出力するため、以下の内容をPlaybookに記入する。

```YAML
  - name: Display all variables/facts known for a host
    debug:
      var: hostvars[inventory_hostname]["ansible_default_ipv4"]["gateway"]
```

実行結果

```bash
  TASK [Display part of variables/facts known for a host] ************************
  ok: [localhost] => {
      "hostvars[inventory_hostname][\"ansible_default_ipv4\"][\"gateway\"]": "192.168.50.1"
  }
```

また、モジュールの実行結果など動的な情報を出力するためのPlaybook内容を以下に示す。

```YAML
  - shell: /usr/bin/uptime
    register: result

  - debug:
      var: result
```

実行結果

```bash
  TASK [command] *****************************************************************
  changed: [localhost]

  TASK [debug] *******************************************************************
  ok: [localhost] => {
      "result": {
          "changed": true,

          "cmd": "/usr/bin/uptime",
          "delta": "0:00:00.003212",
          "end": "2017-01-01 21:30:02.817443",
          "rc": 0,
          "start": "2017-01-01 21:30:02.814231",
          "stderr": "",
          "stdout": " 21:30:02 up 12:38,  8 users,  load average: 1.13, 1.31, 1.14",
          "stdout_lines": [
              " 21:30:02 up 12:38,  8 users,  load average: 1.13, 1.31, 1.14"
          ],
          "warnings": []
      }
  }
```

#### copy

ローカルマシン上のファイルをリモートノードにコピーし、適切なファイルパーミッションを設定する。注意すべきなのは、ファイルをコピーする前に、コピー元とコピー先のファイルのchecksumを比較する。同一の場合はコピーせず、OK状態を返す。異なっている場合のみコピーを実行し、changed状態を返す。

##### ファイルパーミッション設定

modeパラメータを使ってパーミッションを設定する。設定の方式は数字でも、符号形式"u=rw,g=r,o=r”, ”u+rw,g-wx,o-rwx” でも問題ない。

```YAML
- copy:
    src: /srv/myfiles/foo.conf
    dest: /etc/foo.conf
    owner: foo
    group: foo
    mode: 0644
```

##### リモートノード上ファイルのバックアップ

backupパラメータがyesになっている時に、コピーする前にリモートノード上のファイルのバックアップを取るようになる。もしコピー元＆先のファイルが同一であれば、コピー処理が実行されず、バックアップも実行されなくなる。

```YAML
- copy:
    src: sudoers
    dest: /tmp
    backup: yes
```

##### コピー後の検証

validate パラメータに検証の為のコマンドを設定する。通常の場合、検証が必要なのはコピー後のファイルなので、%s で指定することができる。copyモジュールにvalidate変数が存在する場合は、コピー処理が正常に終了したことに加えて、validataの命令も正常と返す時のみ、copyモジュールの実行が成功になる。

以下の例では、visudo -cf /etc/sudoers は sudoers ファイルを検証するための命令である。

```YAML
- copy:
    src: /mine/sudoers
    dest: /etc/sudoers
    validate: 'visudo -cf %s'
```

#### template

普通のファイルをコピーする場合は、copyモジュールで充分だが、コピー先ファイルの内容を動的に変更したい場合、templateモジュールを利用する必要がある。
例えば、apacheをインストールした後、テストのためリモートノードにindex.htmlファイルをコピーし、リモートノードのホスト名とIPアドレスを表示させたい時、templateを利用したほうがいい。
Index.html内、変更したい部分を変数として記入する。templateはpythonのj2テンプレートを利用している。j2を理解する必要がないが、変数の書き方は`\{\{` `\}\}`で囲むことを分かれば問題がない。

##### templateファイルの構文

Templateなので、可読性のため j2 拡張子をファイルにつける。下記の index.html.j2 ファイルに二つの変数ansible_hostname と ansible_default_ipv4.address が書かれている。

```HTML
<html>
<title>Demo</title>
<body>
<div class="block" style="height: 99%;">
    <div class="centered">
        <h1>#46 Demo</h1>
        <p>Served by \{\{ ansible_hostname \}\} (\{\{ ansible_default_ipv4.address \}\}).</p>
    </div>
</div>
</body>
</html>
```

##### facts変数を利用するtemplate

index.html.j2で使われている変数ansible_hostnameとansible_default_ipv4.addressはfacts変数であり、ansibleはその内容を調べ、直接Playbookで利用することができるし、templateで利用することもできる。そのため、templateにこの変数を記入した場合は特にパラメータを入力する必要はない。

```YAML
- name: Write the default index.html file
  template: src=templates/index.html.j2 dest=/var/www/html/index.html
```

##### 一般変数を利用するtemplate

例えば、httpd.conf.j2をリモートノードにコピーした後、デフォルトのhttpポートを設定したい場合、templateの一般変数を利用して実現できる。templateファイル httpd.conf.j2の中での一般変数の利用方法は同じく`\{\{\}\}`:

```YAML
ServerRoot "/etc/httpd"
...
Listen \{\{ http_port \}\}
...
```

一般変数はtemplateを読み込む時ではなく、Playbook内のvars キーワードで定義される。もちろんPlaybook内で直接利用できる変数は、template内でも利用できる。inventory内の変数の定義については後章で説明する。

```YAML
- hosts: localhost
  vars:
    http_port: 8080
  remote_user: root
  tasks:

  - name: Write the configuration file
    template: src=templates/httpd.conf.j2 dest=/etc/httpd/conf/httpd.conf
```

templateモジュールはcopyモジュールと同じく、ファイルをリモートノードにコピーするだけではなく、パーミッションの設定、バックアップ、検証機能などもできる。

```YAML
- template:
    src: etc/ssh/sshd_config.j2
    dest: /etc/ssh/sshd_config.j2
    owner: root
    group: root
    mode: '0600'
    validate: /usr/sbin/sshd -t %s
    backup: yes
```

#### file

fileモジュールは、リモートノード上のファイル、シンボリック、フォルダの作成、削除、またはパーミションの設定を行う。

##### ファイルのパーミッションの変更

mode変数には直接数字(頭1文字は 0)でも、パーミッション設定内容でも、パーミッションの追加/削除でも設定することができます。詳細については以下の例で示す。

```YAML
- file:
    path: /etc/foo.conf
    owner: foo
    group: foo
    mode: 0644
    #mode: "u=rw,g=r,o=r"
    #mode: "u+rw,g-wx,o-rwx"
```

##### シンボリックリンク作成

ここで注意すべきところは、srcとdestパラメータの意味はcopyモジュールと異なり、fileモジュールの操作対象のファイルは全てリモートノード上にある。

```YAML
- file:
    src: /file/to/link/to
    dest: /path/to/symlink
    owner: foo
    group: foo
    state: link
```

##### 新しいファイル作成

Touchコマンドのように新しいファイルを作成

```YAML
- file:
    path: /etc/foo.conf
    state: touch
    mode: "u=rw,g=r,o=r"
```

新しいフォルダを作成

```YAML
# create a directory if it doesn't exist
- file:
    path: /etc/some_directory
    state: directory
    mode: 0755
```

#### user

ユーザモジュールはリモートノードのユーザアカウントを追加／削除／変更することができ、アカウントの属性を設定することもできる。

##### アカウント追加

ユーザアカウントjohndを追加、uid を 1040に、primary groupをadminに設定する。

```YAML
  - user:
      name: johnd
      comment: "John Doe"
      uid: 1040
      group: admin
```

ユーザアカウントjamesを作成し、このアカウントに二つのグループを追加する。

```YAML
  - user:
      name: james
      shell: /bin/bash
      groups: admins,developers
      append: yes
```

##### アカウント削除

ユーザアカウントjohndを削除する。

```YAML
- user:
    name: johnd
    state: absent
    remove: yes
```

##### アカウントの属性を変更

アカウントjsmithに対し2048-bit のSSH keyを作成し、~jsmith/.ssh/id_rsaに保存する。

```YAML
  - user:
      name: jsmith
      generate_ssh_key: yes
      ssh_key_bits: 2048
      ssh_key_file: .ssh/id_rsa
```

アカウントの無効時刻を追加

```YAML
  - user:
      name: james18
      shell: /bin/zsh
      groups: developers
      expires: 1422403387
```

#### yum

yum モジュールはRed Hat系Linuxのパッケージを管理する。RHEL, CentOS, fedora 21以下のOSをサポートする。fedora 22以上からはdnfを利用するため、dnfモジュールの利用をお勧めする。

##### パッケージのinstallとremove

最新のパッケージをインストール。もし古いパッケージが存在する場合、最新versionにアップデートする。

```YAML
  - name: install the latest version of Apache
    yum:
      name: httpd
      state: latest
```

指定したversionのパッケージをinstall

```YAML
  - name: install one specific version of Apache
    yum:
      name: httpd-2.2.29-1.4.amzn1
      state: present
```

httpdパッケージをremove

```YAML
  - name: remove the Apache package
    yum:
      name: httpd
      state: absent
```

指定したリポジトリtestingからパッケージをinstall

```YAML
  - name: install the latest version of Apache from the testing repo
    yum:
      name: httpd
      enablerepo: testing
      state: present
```

パッケージグループをinstall

```YAML
- name: install the 'Development tools' package group
  yum:
    name: "@Development tools"
    state: present

- name: install the 'Gnome desktop' environment group
  yum:
    name: "@^gnome-desktop-environment"
    state: present
```

ローカルファイルからパッケージをinstall

```YAML
- name: install nginx rpm from a local file
  yum:
    name: /usr/local/src/nginx-release-centos-6-0.el6.ngx.noarch.rpm
    state: present
```

URLからパッケージをinstall

```YAML
- name: install the nginx rpm from a remote repo
  yum:
    name: http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm
    state: present
```

#### service

リモートノード上のサービスを管理する。一般的によく利用されるサービスは、httpd, sshd, nfs, crondなどがある。

##### 起動/停止/再起動

httpdサービスを起動

```YAML
  - service:
      name: httpd
      state: started
```

httpdサービスを停止

```YAML
  - service:
      name: httpd
      state: stopped
```

httpdサービスを再起動

```YAML
  - service:
      name: httpd
      state: restarted
```

httpdサービスをreload

```YAML
  - service:
      name: httpd
      state: reloaded
```

httpdサービスをブート時自動起動に設定

```YAML
- service:
    name: httpd
    enabled: yes
```

ネットワークサービスのポートを起動する

```YAML
- service:
    name: network
    state: restarted
    args: eth0
```

#### firewalld

firewalldモジュールは、サービスやポートに対しfirewalldのルールを設定する。実行中のルールと、永久のルールの両方が設定できる。ただし、firewalldモジュールの条件として、リモートノードのfirewalldのversionは0.2.11以上である必要がある。

##### サービスに対しfirewalldルールを追加

```YAML
- firewalld:
    service: https
    permanent: true
    state: enabled

- firewalld:
    zone: dmz
    service: http
    permanent: true
    state: enabled
```

##### ポートに対しfirewalldルールを追加

```YAML
- firewalld:
    port: 8081/tcp
    permanent: true
    state: disabled

- firewalld:
    port: 161-162/udp
    permanent: true
    state: enabled
```

##### その他のfirewalldルールの例

```YAML
- firewalld:
    rich_rule: 'rule service name="ftp" audit limit value="1/m" accept'
    permanent: true
    state: enabled

- firewalld:
    source: 192.0.2.0/24
    zone: internal
    state: enabled

- firewalld:
    zone: trusted
    interface: eth2
    permanent: true
    state: enabled

- firewalld:
    masquerade: yes
    state: enabled
    permanent: true
    zone: dmz
```

#### shell

shellモジュールは/bin/shを使ってリモートノードで命令を実行する。
もし命令はyumやcopyモジュールで実現できるなら、shellまたはcommandのような命令モジュールが必要なくなる。
また、shellモジュールは操作後の戻り値やstatusをチェックしていないため、実行する必要がない場合でも、もう一回実行される。

$home, $HOME, "<”,  ">”,  “|”, “;” と“&”が利用できる。

* $home

```YAML
  - name: test $home
    shell: echo "Test1" > ~/tmp/test1
```

* &&

```YAML
  - shell: service jboss start && chkconfig jboss on
```

* \>\>

```YAML
  - shell: echo foo >> /tmp/testfoo
```

##### スクリプト実行

```YAML
  - shell: somescript.sh >> somelog.txt
```

命令実行前にカレントディレクトリを変更

```YAML
  - shell: somescript.sh >> somelog.txt
    args:
      chdir: somedir/
```

命令実行前にカレントディレクトリを変更し、somelog.txtが存在しない時にのみactionを実行する。

```YAML
  - shell: somescript.sh >> somelog.txt
    args:
      chdir: somedir/
      creates: somelog.txt
```

Bashを指定し命令を実行する

```YAML
  - shell: cat < /tmp/\*txt
    args:
      executable: /bin/bash
```

#### Command

Shellモジュールと似ていて、リモートノードで命令を実行する。しかし、commandモジュールは $HOME または "<", “>”, “|”, “;” and “&”を利用できない

##### Shell と似た部分

* 一つの命令を実行する

```YAML
  - command: /sbin/shutdown -t now
```

* 命令を実行する前にカレントディレクトリを変更し、databaseファイルがない時に命令を実行

```YAML
  - command: /usr/bin/make_database.sh arg1 arg2
    args:
      chdir: somedir/
      creates: /path/to/database
```

##### Shell と異る部分

* パラメータを渡す方法はShellより一つ多い

```YAML
  - command: /usr/bin/make_database.sh arg1 arg2 creates=/path/to/database
```

* && または >> は利用できない。

下記の書き方で、~/tmp/test3と~/tmp/test4は作成できない。

```YAML
  - name: test $home
    command: echo "test3" > ~/tmp/test3 && echo "test4" > ~/tmp/test4
```

---
title: Python每日获取天气情报并通过邮件通知
date: 2017-04-21 00:16:17
tags:
- Python
---
因为没看天气预报，被大雨浇了几次之后，我打算为我这样的懒人写一个小程序。
很简单，算是Python的一个小练习，用Python实现一个邮件提醒每日天气。

这段程序一共分两步
1. 通过网站获取天气信息
2. 将天气信息通过邮件发送到指定信箱

## 获取天气信息

这里我用了常用的requests和BeautifulSoup4来获取网页并抽取信息。
网站用tenki.jp搜索天气，然后通过id来抽取搜索界面的天气信息框框。
搜索界面如下，可以看到用BS4抽取id为'map_world_point_wrap'的<div>以下的HTML就好了。
我们准备直接发送HTML代码，这样看起来更好看一些。

<!-- more -->

![tenki web](https://raw.githubusercontent.com/xibuka/git_pics/master/weatherbeijing.png)

代码如下
注：soup.find之后需要将内容转换为string格式，不然python2环境下无法发送邮件

``` python
#!/root/.pyenv/shims/python
#-*- coding: UTF-8 -*-

import sys
import time
import requests
from bs4 import BeautifulSoup

#Some User Agents
hds=[{'User-Agent':'Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US; rv:1.9.1.6) Gecko/20091201 Firefox/3.5.6'}]

def weather_notice():

    url='http://www.tenki.jp/world/5/90/54511.html' # beijing, China

    try:
         html = requests.get(url, headers=hds[0], allow_redirects=False, timeout=3)

         if html.status_code == 200:
             soup = BeautifulSoup(html.text.encode(html.encoding), "html.parser")

             town_info_block = soup.find('div', {'id': 'map_world_point_wrap'})
             town_info_block = str(town_info_block)
             print(town_info_block)
    except Exception as e:
        print(url, e, str(time.ctime()))

if __name__ == "__main__":
   weather_notice()
```

运行过后如果得到了一堆HTML内容，证明第一步获取天气情报已经完成。

## 发送邮件设置

接下来我们为上面的代码加入gmail送信功能。
使用MIMEMultipart,MIMEText来设置邮件内容，
使用smtplib来发送邮件。在这里我们用gmail账户来发送邮件。

下面是代码

``` python
#!/root/.pyenv/shims/python
#-*- coding: UTF-8 -*-

import sys
import time
import requests
from bs4 import BeautifulSoup
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

#Some User Agents
hds=[{'User-Agent':'Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US; rv:1.9.1.6) Gecko/20091201 Firefox/3.5.6'}]

def send_email(weather_info_html):

    # setup to list
    tolist= ['TO ADDR 1', 'TO ADDR 2']

    # login 
    fromaddr = "YOUR GOOGLE EMAIL ADDR"
    fromaddr_pw = "PASSWORD"

    server = smtplib.SMTP('smtp.gmail.com', 587)
    server.starttls()
    server.login(fromaddr, fromaddr_pw)

    # make up and send the msg
    msg = MIMEMultipart()
    msg['Subject'] = "Weather Mail" + "[" + time.strftime("%a, %d %b", time.gmtime()) + "]"
    msg['From'] = fromaddr
    msg['To'] = ", ".join(tolist)
    msg.attach(MIMEText(weather_info_html, 'html')) # plain will send plain text
    server.sendmail(fromaddr, tolist, msg.as_string())

    # logout
    server.quit()

def weather_notice():

    url='http://www.tenki.jp/world/5/90/54511.html' # beijing, China

    try:
         html = requests.get(url, headers=hds[0], allow_redirects=False, timeout=3)

         if html.status_code == 200:
             soup = BeautifulSoup(html.text.encode(html.encoding), "html.parser")

             town_info_block = soup.find('div', {'id': 'map_world_point_wrap'})
             town_info_block = str(town_info_block)

    except Exception as e:
        print(url, e, str(time.ctime()))

if __name__ == "__main__":
   weather_notice()
```

执行这个程序，看看你能否收到邮件？

最后就是将这个程序加入crontab定时启动了。
有关crontab -e 的用法我有时间再说，今天太晚了。。。

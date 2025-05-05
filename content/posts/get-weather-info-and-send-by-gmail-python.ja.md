---
title: Pythonで毎日天気情報を取得しGmailで通知する
date: 2017-04-21 00:16:17
tags:
- Python
---
天気予報を見ずに何度か大雨に降られたので、同じようなズボラな人のために小さなプログラムを書いてみました。
とてもシンプルで、Pythonのちょっとした練習にもなります。Pythonで毎日天気をメールで通知する仕組みです。

このプログラムは2つのステップに分かれています。

1. Webサイトから天気情報を取得する
2. 取得した天気情報を指定したメールアドレスに送信する

## 天気情報の取得

ここでは、よく使われるrequestsとBeautifulSoup4を使ってWebページから情報を取得・抽出します。
天気サイトはtenki.jpを使い、idで検索画面の天気情報ブロックを抽出します。
下記のように、BS4でidが'map_world_point_wrap'の`<div>`以下のHTMLを抽出すればOKです。
HTMLコードをそのまま送信することで、見た目もきれいになります。

![tenki web](/img/weatherbeijing.png)

コード例：
注：soup.findの後は内容をstring型に変換しないと、python2環境ではメール送信できません。

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

実行してHTMLが出力されれば、天気情報の取得は完了です。

## メール送信の設定

次に、上記のコードにGmail送信機能を追加します。
MIMEMultipartとMIMETextでメール内容を作成し、smtplibでメールを送信します。ここではGmailアカウントを使います。

コード例：

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

    # 送信先リスト
    tolist= ['TO ADDR 1', 'TO ADDR 2']

    # ログイン情報
    fromaddr = "YOUR GOOGLE EMAIL ADDR"
    fromaddr_pw = "PASSWORD"

    server = smtplib.SMTP('smtp.gmail.com', 587)
    server.starttls()
    server.login(fromaddr, fromaddr_pw)

    # メール作成と送信
    msg = MIMEMultipart()
    msg['Subject'] = "Weather Mail" + "[" + time.strftime("%a, %d %b", time.gmtime()) + "]"
    msg['From'] = fromaddr
    msg['To'] = ", ".join(tolist)
    msg.attach(MIMEText(weather_info_html, 'html')) # plainだとテキストメールになります
    server.sendmail(fromaddr, tolist, msg.as_string())

    # ログアウト
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

このプログラムを実行して、メールが届くか確認してみてください。

最後に、このプログラムをcrontabに登録して定期実行すればOKです。
crontab -eの使い方はまた今度説明します。今日はもう遅いので……

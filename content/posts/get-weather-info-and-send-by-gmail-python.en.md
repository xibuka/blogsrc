---
title: Get Daily Weather Info and Send by Gmail with Python
date: 2017-04-21 00:16:17
tags:
- Python
---
After being caught in the rain several times for not checking the weather forecast, I decided to write a small program for lazy people like me.
It's simple, just a small Python exercise: use Python to send daily weather reminders by email.

This program is divided into two steps:

1. Get weather information from a website
2. Send the weather information to a specified mailbox by email

## Getting Weather Information

Here I used the popular requests and BeautifulSoup4 libraries to fetch and extract information from a webpage.
The website used is tenki.jp to search for weather, then extract the weather info block from the search page by id.
As shown below, you can use BS4 to extract the HTML under the `<div>` with id 'map_world_point_wrap'.
We plan to send the HTML code directly, which looks better.

![tenki web](/img/weatherbeijing.png)

Here is the code:
Note: After soup.find, you need to convert the content to a string, otherwise you can't send the email in Python2.

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

If you get a bunch of HTML content after running, it means the first step of getting the weather info is done.

## Email Sending Setup

Next, let's add Gmail sending functionality to the code above.
Use MIMEMultipart and MIMEText to set up the email content, and use smtplib to send the email. Here we use a Gmail account to send the email.

Here is the code:

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

Run this program and see if you can receive the email?

Finally, just add this program to crontab for scheduled execution.
I'll talk about how to use crontab -e another time, it's too late today...

---
title: 用 Python 编写爬虫
date: 2016-12-01 00:54:09
tags: 
- Python
---
使用 Python 的 Requests 库可以提取并保存网页内容。
然后，利用 BeautifulSoup 库可以抽取你想要的信息。

## 什么是 Requests？

Requests 是 Python 的 HTTP 库，比 urllib2 好用太多了。
官网介绍：
>Requests is an Apache2 Licensed HTTP library, written in Python, for human beings.

正如介绍所说，它让代码更易于人类阅读和编写。

## 什么是 BeautifulSoup？

BeautifulSoup 是一个可以在 Python 中使用的 HTML 和 XML 解析器。

## 安装

```sh
pip install requests
pip install BeautifulSoup
```

## 用法

```sh
import requests
from bs4 import BeautifulSoup
```

requests 库为每种 HTTP 方法都提供了一一对应的方法。

```sh
requests.get('URL')
requests.post('URL')
requests.put('URL')
requests.delete('URL')
requests.head('URL')
```

## 第一个爬虫

让我们来抓取亚马逊图书排行榜的内容。需求如下：

* 修改请求头，让它看起来像浏览器在访问。
* 只有页面获取成功时才保存页面内容到文件。
* 输出畅销榜前 1-20 名图书的排名和标题。

```python
import requests
import time
from bs4 import BeautifulSoup

def anaylise_ranking_books(html):
    soup = BeautifulSoup(html.text.encode(html.encoding), "html.parser")

    # 抽取排行榜图书信息，可通过 div 标签 class 为 zg_itemRow 定位。
    books = soup.findAll("div", {"class" : "zg_itemRow"})

    # 进一步抽取每本书的详细信息。
    for book in books:
        # 排名
        rank_number = book.find("span", {"class" : "zg_rankNumber"}).text.strip()
        # 标题
        title = book.find("div", {"class" : "a-fixed-left-grid-col a-col-right"})
        title = title.find("a", {"class" : "a-link-normal"}).text.strip()

        print(rank_number, title)

def get_url_info(url):
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 6.2; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.87 Safari/537.36"
    }
    try:
        html = requests.get(url, headers=headers, allow_redirects=False, timeout=3)

        if html.status_code == 200:
            print(url, '@ok200', str(time.ctime()))
            with open('content.html', 'wb') as fw:
                fw.write(html.content)
                fw.close()
            anaylise_ranking_books(html)

        else:
            print(url, 'wrong', str(time.ctime()))
    except Exception as e:
        print(url, e, str(time.ctime()))

if __name__ == '__main__':
    get_url_info("https://www.amazon.co.jp/gp/bestsellers/books")
```

运行

```bash
$ python 02_anaylize_data.py
https://www.amazon.co.jp/gp/bestsellers/books @ok200 Sun Dec  4 23:23:34 2016
1. 全部微波炉！瘦身菜肴：省时、省力、不失败（小学馆实用系列 LADY BIRD）
2. 口袋妖怪 太阳·月亮 官方攻略 上下册 完全故事攻略+完全阿罗拉图鉴
3. 瘦身菜肴：作者50多岁，一年减重26公斤，无反弹！（小学馆实用系列 LADY BIRD）
4. SD高达 G世代 创世 最终完全攻略
5. 复活的变态
6. 【Amazon.co.jp限定】附霍格沃茨地图 哈利·波特与被诅咒的孩子 第一部、第二部 特别彩排版
7. 老公也能瘦的菜肴：肉类和面条也OK的豪爽系（LADY BIRD 小学馆实用系列）
8. 【限定】"识子流"祈福参拜礼仪手册套装（附招福御神签手册）
9. 偶像大师 百万人演唱会！5 原创CD&画集特别版（特品）
10. LisAni! Vol.27.1《LoveLive!》我们的音乐大全
11. 于是生活继续（文春文库）
12. 小说《你的名字。》（角川文库）
13. 生产力——麦肯锡持续要求组织和人才的东西
14. 【Amazon.co.jp限定】可恨的他 美丽的他2 附新作短篇小说（Chara文库）
15. 小王子（新潮文库）
16. 工作的男人（文春文库）
17. Comic Market 91 目录
18. 被讨厌的勇气——自我启发源流"阿德勒"的教诲
19. 最终幻想XV 终极典藏 - 剧情SIDE -（SE-MOOK）
20. 最终幻想XV 终极典藏 - 战斗+地图SIDE -（SE-MOOK）
```

运行后会生成 content.html 文件，页面源码会被保存下来。

---
title: Pythonでスパイダーを作る
date: 2016-12-01 00:54:09
tags: 
- Python
---
PythonのRequestsライブラリを利用してウェブページの内容を抽出し保存する。
そして、BeautifulSoupライブラリを利用し、欲しい情報を抽出する。

## Requestsとは
RequestsはPythonのHTTPライブラリで、urllib2より断然使いやすい。
公式サイトに、
>Requests is an Apache2 Licensed HTTP library, written in Python, for human beings.

の説明の通り、人間によって読みやすくコーディングできる。

## Beautifulsoupとは
BeautifulSoupはPythonで動作するHTMLとXMLのパーサーです。

<!-- more -->

## インストール
```
pip install requests
pip install BeautifulSoup
```

## 使い方
```
import requests
from bs4 import BeautifulSoup
```

requestsライブラリでは、各種のHTTPメソッドに１対１のメソッドがあります。
```
requests.get('URL')
requests.post('URL')
requests.put('URL')
requests.delete('URL')
requests.head('URL')
```

## 初めてのスパイダー
アマゾンの本のランキングの内容を取ってみよう。以下のことを要件とする。
* ブラウザがアクセスしているように、ヘッダ情報を編集する。
* ページの取得が成功の場合のみ、ページ内容をファイルに保存する。
* 売れ筋ランキングの1-20位の本の順位とタイトルを出力する。

``` python
import requests
import time
from bs4 import BeautifulSoup
                                                                                                                                              
def anaylise_ranking_books(html):
    soup = BeautifulSoup(html.text.encode(html.encoding), "html.parser")
 
    # ランキングの本の情報を抽出する, divタグでzg_itemrowのクラスで特定できる。
    books = soup.findAll("div", {"class" : "zg_itemRow"})
 
    # 各本の情報をさらに細かく抽出する。
    for book in books:
        # 順位
        rank_number = book.find("span", {"class" : "zg_rankNumber"}).text.strip()
        # タイトル
        title       = book.find("div", {"class" : "a-fixed-left-grid-col a-col-right"})
        title       = title.find("a", {"class" : "a-link-normal"}).text.strip()
 
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

実行

```
$ python 02_anaylize_data.py 
https://www.amazon.co.jp/gp/bestsellers/books @ok200 Sun Dec  4 23:23:34 2016
1. 全部レンチン! やせるおかず 作りおき: 時短、手間なし、失敗なし (小学館実用シリーズ LADY BIRD)
2. ポケットモンスター サン・ムーン 公式ガイドブック 上・下セット 完全ストーリー攻略+完全アローラ図鑑
3. やせるおかず 作りおき: 著者50代、1年で26キロ減、リバウンドなし! (小学館実用シリーズ LADY BIRD)
4. SDガンダム ジージェネレーション ジェネシス ファイナルコンプリートガイド
5. 蘇える変態
6. 【Amazon.co.jp限定】 ホグワーツMAP付き　ハリー・ポッターと呪いの子 第一部、第二部 特別リハーサル
7. 夫もやせるおかず 作りおき: お肉や麺もOKなガッツリ系 (LADY BIRD 小学館実用シリーズ)
8. 【限定】“識子流"ごりやく参拝マナー手帖セット(福を呼ぶおみくじ帖付)
9. アイドルマスター ミリオンライブ! 5 オリジナルCD&画集付特別版 (特品)
10. リスアニ! Vol.27.1 「ラブライブ! 」僕らの音楽大全
11. そして生活はつづく (文春文庫)
12. 小説 君の名は。 (角川文庫)
13. 生産性―――マッキンゼーが組織と人材に求め続けるもの
14. 【Amazon co.jp限定】憎らしい彼 美しい彼2 書き下ろしショートストーリー付き (キャラ文庫)
15. 星の王子さま (新潮文庫)
16. 働く男 (文春文庫)
17. コミックマーケット 91 カタログ
18. 嫌われる勇気―――自己啓発の源流「アドラー」の教え
19. ファイナルファンタジーXV アルティマニア -シナリオSIDE- (SE-MOOK)
20. ファイナルファンタジーXV アルティマニア -バトル+マップSIDE- (SE-MOOK)
```

そして、content.htmlファイルが生成され、ページのソースコードが保存された。

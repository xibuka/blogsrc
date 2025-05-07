---
title: Creating a Spider with Python
date: 2016-12-01 00:54:09
tags: 
- Python
---

Using Python's Requests library, you can extract and save the contents of a web page.
Then, by using the BeautifulSoup library, you can extract the information you want.

## What is Requests?

Requests is a Python HTTP library that is much easier to use than urllib2.
As described on the official site:
>Requests is an Apache2 Licensed HTTP library, written in Python, for human beings.

As the description says, it allows you to write code that is easy for humans to read.

## What is BeautifulSoup?

BeautifulSoup is an HTML and XML parser that works with Python.

## Installation

```sh
pip install requests
pip install BeautifulSoup
```

## How to Use

```sh
import requests
from bs4 import BeautifulSoup
```

The requests library provides one-to-one methods for each HTTP method.

```sh
requests.get('URL')
requests.post('URL')
requests.put('URL')
requests.delete('URL')
requests.head('URL')
```

## Your First Spider

Let's try to get the ranking of books on Amazon. The requirements are as follows:

* Edit the header information so it looks like a browser is accessing the site.
* Only save the page content to a file if the page is successfully retrieved.
* Output the rank and title of the top 1-20 best-selling books.

```python
import requests
import time
from bs4 import BeautifulSoup

def anaylise_ranking_books(html):
    soup = BeautifulSoup(html.text.encode(html.encoding), "html.parser")

    # Extract information about ranked books. You can identify them by the class 'zg_itemRow' in div tags.
    books = soup.findAll("div", {"class" : "zg_itemRow"})

    # Extract more detailed information for each book.
    for book in books:
        # Rank
        rank_number = book.find("span", {"class" : "zg_rankNumber"}).text.strip()
        # Title
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

Execution

```bash
$ python 02_anaylize_data.py
https://www.amazon.co.jp/gp/bestsellers/books @ok200 Sun Dec  4 23:23:34 2016
1. All Microwave! Slimming Side Dishes: Quick, No Hassle, No Fail (Shogakukan Practical Series LADY BIRD)
2. Pokémon Sun & Moon Official Guidebook Complete Story Walkthrough + Complete Alola Pokédex
3. Slimming Side Dishes: Author in her 50s, Lost 26kg in a Year, No Rebound! (Shogakukan Practical Series LADY BIRD)
4. SD Gundam G Generation Genesis Final Complete Guide
5. The Revived Pervert
6. [Amazon.co.jp Limited] Harry Potter and the Cursed Child Parts One and Two Special Rehearsal Edition with Hogwarts MAP
7. Husband Also Slims Down Side Dishes: Meat and Noodles OK, Hearty Types (LADY BIRD Shogakukan Practical Series)
8. [Limited] "Shikiko Style" Good Luck Shrine Manners Handbook Set (with Fortune Omikuji Book)
9. The Idolmaster Million Live! 5 Original CD & Art Book Special Edition (Special Item)
10. LisAni! Vol.27.1 "Love Live!" Our Music Encyclopedia
11. And Life Goes On (Bunshun Bunko)
12. Novel Your Name. (Kadokawa Bunko)
13. Productivity—What McKinsey Continues to Demand from Organizations and Talent
14. [Amazon.co.jp Limited] Hateful Him, Beautiful Him 2 with Newly Written Short Story (Chara Bunko)
15. The Little Prince (Shinchosha Bunko)
16. Working Man (Bunshun Bunko)
17. Comic Market 91 Catalog
18. The Courage to Be Disliked—The Teachings of Adler, the Source of Self-Help
19. Final Fantasy XV Ultimania - Scenario SIDE - (SE-MOOK)
20. Final Fantasy XV Ultimania - Battle + Map SIDE - (SE-MOOK)
```

After running, a file named content.html is generated, and the page source code is saved.

---
title: Pythonの出力フォーマット
date: 2016-10-29 00:28:06
tags: 
- Python
- CodeWar
---
今日もCodeWarの問題を練習した。[RGB To Hex Conversion](https://www.codewars.com/kata/513e08acc600c94f01000001)

問題を簡略化にすると、rgbの数字を16進に変換し出力する。

```sh
rgb(255, 255, 255) # returns FFFFFF
rgb(255, 255, 300) # returns FFFFFF
rgb(0,0,0) # returns 000000
rgb(148, 0, 211) # returns 9400D3
```

直接hexで変換すると、”0x”が余計についているし、"00"が"0"になる。
sprintf見たいな関数が無いかなっと思いながら、このサイトを見つけた。
[Cのsprintfのような文字列フォーマット](http://d.hatena.ne.jp/m_py_study/20100128/1264630396)

なんと、フォーマットを指定すれば数字が直接変換される！桁数の指定も出来る。

そして自分の答えは

```python
def limit(a):
    return min(max(a, 0), 255)

def rgb(r, g, b):        
    return  "%02X%02X%02X" % (limit(r), limit(g), limit(b),)
```

便利だな~

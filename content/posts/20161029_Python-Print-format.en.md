---
title: Python Output Formatting
date: 2016-10-29 00:28:06
tags: 
- Python
- CodeWar
---
I practiced another CodeWar problem today: [RGB To Hex Conversion](https://www.codewars.com/kata/513e08acc600c94f01000001)

To put it simply, the problem is to convert RGB numbers to hexadecimal and output them.

```sh
rgb(255, 255, 255) # returns FFFFFF
rgb(255, 255, 300) # returns FFFFFF
rgb(0,0,0) # returns 000000
rgb(148, 0, 211) # returns 9400D3
```

If you convert directly with hex, you get an extra "0x" and "00" becomes "0".
I wondered if there was a function like sprintf, and found this site:
[String formatting like C's sprintf](http://d.hatena.ne.jp/m_py_study/20100128/1264630396)

Surprisingly, if you specify the format, the number is converted directly! You can also specify the number of digits.

Here is my answer:

```python
def limit(a):
    return min(max(a, 0), 255)

def rgb(r, g, b):        
    return  "%02X%02X%02X" % (limit(r), limit(g), limit(b),)
```

So convenient~

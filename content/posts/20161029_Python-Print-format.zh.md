---
title: Python 的输出格式化
date: 2016-10-29 00:28:06
tags: 
- Python
- CodeWar
---
今天又练习了一道 CodeWar 的题目：[RGB To Hex Conversion](https://www.codewars.com/kata/513e08acc600c94f01000001)

简单来说，就是把 rgb 数字转换成十六进制输出。

```sh
rgb(255, 255, 255) # returns FFFFFF
rgb(255, 255, 300) # returns FFFFFF
rgb(0,0,0) # returns 000000
rgb(148, 0, 211) # returns 9400D3
```

直接用 hex 转换会多出"0x"，而且"00"会变成"0"。
想着有没有类似 sprintf 的函数，结果找到了这个网站：
[像 C 的 sprintf 一样的字符串格式化](http://d.hatena.ne.jp/m_py_study/20100128/1264630396)

没想到只要指定格式，数字就能直接转换！还能指定位数。

我的解答如下：

```python
def limit(a):
    return min(max(a, 0), 255)

def rgb(r, g, b):        
    return  "%02X%02X%02X" % (limit(r), limit(g), limit(b),)
```

真方便啊~

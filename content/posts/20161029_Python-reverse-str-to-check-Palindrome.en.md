---
title: Checking Palindromes in Python
date: 2016-10-29 01:21:18
tags:
- Python
- CodeWar
---
I solved another problem: [Palindrome chain length](https://www.codewars.com/kata/palindrome-chain-length/python)

This is a calculation problem about palindromes.
A palindrome is a string that, when split in the middle, has left and right sides that are symmetric in reverse order.
For example, "あいういあ" is a palindrome, while "あいうえお" is not.
The same applies to numbers: 5, 44, 171, 4884 are palindromes, while 43, 194, 4773 are not.

This problem asks, for a given number, how many times a specific calculation must be performed to make it a palindrome.
The calculation is: reverse the digits of the number and add it to the original number.

For example, if 87 is given, it becomes a palindrome after 4 calculations, so the return value is 4.

```sh
87 + 78     = 165; 
165 + 561   = 726; 
726 + 627   = 1353; 
1353 + 3531 = 4884;
```

The tricky part is how to reverse the digits of a number.
After some research, I found it surprisingly easy, and it can be done in one line. [Reverse string in Python](http://d.hatena.ne.jp/redcat_prog/20111104/1320395840)

```python
str(n)       # Convert number to string
str(n)[::-1] # Convert number to string and reverse it
```

This way, you can extract elements from the end of the string to the beginning one by one.

Here is my answer to the problem:

```python
def palindrome_chain_length(n):
    cnt=0
    while str(n) != str(n)[::-1] :
        cnt += 1
        n   += int(str(n)[::-1])
    return cnt
```

Wow, that's convenient! Now I can sleep well tonight~

---
title: Install vim 8 with python support on mac
date: 2017-04-15 00:50:08
tags: 
- VIM
---

Today I configure my development envirment for my mac pro.
And I find it is much easier to install VIM 8 with python support use brew.
(much more easier than cent 7)

If you have brew, you just need to run

```bash
brew install --with-python vim
```

If you want both python3 and python2 support, just run this

```bash
brew install --with-python --with-python3 vim
```

Update: you may need to use below command on some latest OS for python2

```bash
brew install --with-python@2
```

may be you need to remove the old vim bin file,

```bash
rm -f /usr/local/bin/vim
```

and re-link the vim

```bash
brew link --overwrite vim

```

done! enjoy your vim~

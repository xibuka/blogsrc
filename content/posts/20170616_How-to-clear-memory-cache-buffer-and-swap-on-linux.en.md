---
title: How to clear memory cache, buffer and swap on linux
date: 2017-06-16 12:05:35
tags:
- Linux
---
## How to clear cache in Linux

* Clear PageCache only

```zsh
sync ; echo 1 > /proc/sys/vm/drop_caches
```

* Clear Dentries and inodes(metadata)

```zsh
sync ; echo 2 > /proc/sys/vm/drop_caches
```

* Clear All cache(include PageCache and Dentries and inode)

```zsh
sync ; echo 3 > /proc/sys/vm/drop_caches
```

## How to clear swap space in Linux

```zsh
swapoff -a && swapon -a
```

NOTE: This may make your system unstable when you have low RAM already. The
data in the swapspace will force move to your RAM and may cause a OOM when you
don't have free space in RAM.

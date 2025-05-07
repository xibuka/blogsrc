---
title: 如何在Linux下清理内存缓存、buffer和swap
date: 2017-06-16 12:05:35
tags:
- Linux
---
## 如何在Linux下清理缓存

* 只清理 PageCache

```zsh
sync ; echo 1 > /proc/sys/vm/drop_caches
```

* 清理 Dentry 和 inode（元数据）

```zsh
sync ; echo 2 > /proc/sys/vm/drop_caches
```

* 清理所有缓存（包括 PageCache、Dentry 和 inode）

```zsh
sync ; echo 3 > /proc/sys/vm/drop_caches
```

## 如何在Linux下清理swap空间

```zsh
swapoff -a && swapon -a
```

注意：如果你的RAM本来就很少，这个操作可能会导致系统不稳定。
swap空间中的数据会被强制移到内存，如果内存不足，可能会导致OOM（内存溢出）。

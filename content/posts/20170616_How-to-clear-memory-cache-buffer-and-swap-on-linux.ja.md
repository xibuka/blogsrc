---
title: Linuxでメモリキャッシュ・バッファ・スワップをクリアする方法
date: 2017-06-16 12:05:35
tags:
- Linux
---
## Linuxでキャッシュをクリアする方法

* PageCacheのみをクリア

```zsh
sync ; echo 1 > /proc/sys/vm/drop_caches
```

* Dentryとinode（メタデータ）をクリア

```zsh
sync ; echo 2 > /proc/sys/vm/drop_caches
```

* すべてのキャッシュ（PageCache、Dentry、inodeを含む）をクリア

```zsh
sync ; echo 3 > /proc/sys/vm/drop_caches
```

## Linuxでスワップ領域をクリアする方法

```zsh
swapoff -a && swapon -a
```

注意：すでにRAMが少ない場合、この操作はシステムを不安定にする可能性があります。
スワップ領域のデータがRAMに強制的に移動され、RAMに空きがない場合はOOM（メモリ不足）になることがあります。

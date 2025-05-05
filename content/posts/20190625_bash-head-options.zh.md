---
title: bash 脚本开头常用选项
date: 2019-06-25 00:12:59
tags: 
- bash
---

命令失败时立即退出脚本

```bash
set -o errexit
set -e
```

引用未定义变量时输出错误并立即退出脚本

```bash
set -o nounset
set -u
```

即使管道中的某个命令失败也让脚本退出

```bash
set -o pipefail
```

---
title: The begining of bash script
date: 2019-06-25 00:12:59
tags: 
- bash
---

exit script immediately when a command fails

```bash
set -o errexit
set -e
```

output error and exit script immediately when refer to a undefine variable.

```bash
set -o nounset
set -u
```

exit script even a command fails before a pipe

```bash
set -o pipefail
```

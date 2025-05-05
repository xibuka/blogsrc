---
title: bashスクリプトの冒頭で使うオプション
date: 2019-06-25 00:12:59
tags: 
- bash
---

コマンドが失敗した時に即座にスクリプトを終了する

```bash
set -o errexit
set -e
```

未定義変数を参照した時にエラーを出力して即座にスクリプトを終了する

```bash
set -o nounset
set -u
```

パイプ内のコマンドが失敗してもスクリプトを終了する

```bash
set -o pipefail
```

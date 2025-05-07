---
title: psコマンドの出力をソートする方法
date: 2017-09-19 14:11:37
tags:
- Linux
---

psコマンドにはプロセスをソートできる`--sort`オプションがあります。

```bash
--sort spec
       ソート順を指定します。ソート構文は
       [+|-]key[,[+|-]key[,...]] です。STANDARD FORMAT SPECIFIERSセクションから複数文字のキーを選択します。
       「+」は省略可能で、デフォルトは昇順（数値または辞書順）です。kと同じです。
       例: ps jax --sort=uid,-ppid,+pid
```

### メモリでps出力をソートする

#### メモリ使用量が多い順（高→低）

一番上が最大値になります。

```bash
ps aux --sort -rss
```

#### メモリ使用量が少ない順（低→高）

一番下が最大値になります。

```bash
ps aux --sort rss
```

### CPU使用率でps出力をソートする

#### CPU使用率が高い順（高→低）

一番上が最大値になります。

```bash
ps aux --sort -pcpu
```

#### CPU使用率が低い順（低→高）

一番下が最大値になります。

```bash
ps aux --sort rss
```

### その他のソート指定子

psコマンドのmanページを参照してください。

```man
STANDARD FORMAT SPECIFIERS
       出力フォーマット（-oオプション等）やGNUスタイルの--sortオプションで使用できるキーワード一覧です。

       例: ps -eo pid,user,args --sort user

       このpsは他の実装で使われている多くのキーワードも認識しようとします。

       args, cmd, comm, command, fname, ucmd, ucomm, lstart, bsdstart, start などはスペースを含む場合があります。
       一部のキーワードはソートに使えない場合があります。

       CODE        HEADER    説明

       %cpu        %CPU      プロセスのCPU使用率（##.#形式）。現在はcputime/realtime比率（%）。
                             100%にはならない場合もあります（pcpuエイリアス）。

       %mem        %MEM      プロセスの常駐セットサイズと物理メモリの比率（%）。(pmemエイリアス)

       ...（省略。詳細はmanページ参照）...
```

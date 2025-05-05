---
title: "Moving From Hexo to Hugo"
date: 2020-03-30T14:07:21+09:00
draft: false
---

## HexoからHugoに

今までHexoでブログを書いたが、Golang勉強のついでにHugoに移しました。
理由はいろいろありますが、主な点は以下

1. Hexoは複数のモジュールを使うので、たまにインストールがコケる
2. それに対しHugoはバイナリ一つで十分
3. HTMLファイル生成のスピード、HexoよりHugoが断然に速い

Hugoのインストール方法や利用方法については割愛しましたが、今回のブログ移転で
実際に会った問題を整理する

### Tagの付け方

Hexoの場合、以下のタグの付け方が大丈夫でしたが、Hugoの時はだめでした

```config
tag: Python
```

全部以下に統一すれば問題ない

```conf
tags:
- Python
```

### Blog mdファイルの保存場所

これはthemeによって異なります。今回はEvenを利用したのでpostになっています。

### 生成したブログページとGithub Actionの連携

Hexoの場合、`deploy`のサブコマンドでGithubにPush出来ましたが、Hugoの場合はでき
ません。`Hugo deploy`コマンドは一応ありますが、AWS,GCE,Azure向けでした。
[https://gohugo.io/hosting-and-deployment/hugo-deploy/](https://gohugo.io/hosting-and-deployment/hugo-deploy/)

そのためファイルを生成して手動でgithub pageのレポジトリーにpushする必要がありま
す。生成したブログページのファイルが`public`ディレクトリにあります。
Github Actionを利用すれば、新しい記事を書いてpushしたら、上記の処理が全自動に
出来ます。そのやり方は次の記事に纏めます。

### httpsの対応

Hugoと関係ないが、ついでにCloudFlareを使ってhttpsへ対応した。

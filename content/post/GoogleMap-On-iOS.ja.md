---
title: iPhoneでGoogleマップを表示する時のメモ
date: 2016-11-01 01:16:21
tags:
 - GoogleMap
 - iOS
---
GoogleマップをiPhone上に表示したい時にはまったことを残す。

[Google Maps API > iOS向け > Maps SDK for iOS](https://developers.google.com/maps/documentation/ios-sdk/start?hl=ja#google_maps_sdk)を参考に、とりあえず画面上GoogleMapを表示させようの所、画面が真っ白で何も表示されない。

そして、コンソールには以下のエラーメッセージが出ていた。

```
ClientParametersRequest failed, 0 attempts remaining (0 vs 6). Error Domain=com.google.HTTPStatus Code=400
```
ネットで調べたところ、この[サイト](http://www.byteblocks.com/Post/ClientParametersRequest-failed-error-with-Google-Maps-SDK)を見つけた。
そして自分の場合は、三つ目の見直しで、自分のAPIキーが「無効」になっている。。

このエラーの原因は、だいたいAPIキーの設定に何か間違っているようです。
以下の見直しを確認すべき。
- APIキーを生成するとき、xcodeのProjectのbundle IDを設定した方がいい。このパラメータは「任意」ってGoogleが言ったが、やはり設定した方が無難。
- アプリのBundleIDを変更した場合、APIキーを再生成しましょう。
- Google Developersのダッシュボードで「Google Maps SDK for iOS」が有効になっていることを確認しましょう。デフォルトでは無効になっている。(今回はここにはまった)



時間があったらAPIキー有効の画面もアップする予定

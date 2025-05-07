---
title: iPhone上显示Google地图的注意事项
date: 2016-11-01 01:16:21
tags:
 - GoogleMap
 - iOS
---
记录一下在iPhone上显示Google地图时遇到的坑。

参考了[Google Maps API > iOS向け > Maps SDK for iOS](https://developers.google.com/maps/documentation/ios-sdk/start?hl=zh-cn#google_maps_sdk)，想在屏幕上显示Google Map，结果页面一片空白，什么都没有。

控制台里出现了如下错误信息：

```sh
ClientParametersRequest failed, 0 attempts remaining (0 vs 6). Error Domain=com.google.HTTPStatus Code=400
```

在网上查了一下，发现了这个[网站](http://www.byteblocks.com/Post/ClientParametersRequest-failed-error-with-Google-Maps-SDK)。
我自己的情况是第三条，API Key 变成了"无效"。

这个错误大多是API Key设置有误导致的。请检查以下几点：

- 生成API Key时，建议设置Xcode工程的bundle ID。虽然Google说这个参数"可选"，但最好还是设置。
- 如果更改了App的Bundle ID，请务必重新生成API Key。
- 在Google Developers控制台确认"Google Maps SDK for iOS"已启用。默认是未启用的。（我这次就是卡在这里）

有时间的话，准备把API Key启用界面的截图也上传一下。

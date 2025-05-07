---
title: hexoエラー './build/Release/DTraceProviderBindings' の修正
date: 2017-04-21 00:56:19
tags:
- Hexo
---

hexoコマンドを実行するたびに、以下のようなうるさいエラーメッセージが表示されます。

```sh
Error: Cannot find module './build/Release/DTraceProviderBindings'
```

これは単なるトレースエラーで作業自体は止まりませんが、とてもノイズで、どうしても消したいと思いました。

以下のリンクから、
[https://github.com/hexojs/hexo/issues/1922](https://github.com/hexojs/hexo/issues/1922)
[https://github.com/yarnpkg/yarn/issues/1915](https://github.com/yarnpkg/yarn/issues/1915)

原因はdtrace-providerパッケージであることが分かりました。
自分はこのパッケージを全く使っていないので、アンインストールしたいだけです。

```sh
npm uninstall dtrace-provider -g
```

しかし、このパッケージはhexoに関連しているため、削除されません…
以下のコマンドでまだ存在することが確認できます。

```sh
npm list | grep dtrace
```

では、環境をクリーンアップするために、hexo-cliとdtrace-providerの両方をアンインストールします。

* 注意: コマンドはsudoで実行してください

```sh
sudo npm uninstall hexo-cli -g
sudo npm uninstall dtrace-provider -g
```

次に、hexo-cliを--no-optionalオプション付きでインストールし、dtrace-providerがインストールされていないことを確認します。

* 注意: コマンドはsudoで実行してください

```sh
sudo npm install hexo-cli --no-optional -g
```

これで、世界が再び静かになりました。:)

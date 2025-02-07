---
title: PythonでGoogle maps のapiを利用する
date: 2016-11-12 01:22:46
tags:
- GoogleMap
- Python
---
PythonでGoogle mapsのAPI を利用しルート検索をやってみた。

利用するモジュールは[googlemaps/google-maps-services-python](https://github.com/googlemaps/google-maps-services-python)

環境構築は以下のコマンドでOK, ついでにipythonもインストールする。

```
$ pip install googlemaps
$ pip install ipython
```

あと、GoogleのAPIキーの申請が必要なので、[Google APIs](https://console.developers.google.com/apis/dashboard)で申請＆有効にする。

ここまで問題なかったら、早速使ってみよう。
戸塚駅から踊場駅まで、車のルート情報を取得



```
$ ipython
Python 3.5.1 (default, Sep  1 2016, 00:20:33) 
Type "copyright", "credits" or "license" for more information.

IPython 5.1.0 -- An enhanced Interactive Python.
?         -> Introduction and overview of IPython's features.
%quickref -> Quick reference.
help      -> Python's own help system.
object?   -> Details about 'object', use 'object??' for extra details.

In [1]: import googlemaps

In [2]: gmaps = googlemaps.Client(key='AIzaSyCuxTpu4wHcCz1M9S3GNLMfbCYmrc-b-dg')

In [3]: directions_result = gmaps.directions('戸塚駅','踊場駅',mode="driving",alternatives=False,language="ja")

In [4]: directions_result
Out[4]: 
[{'bounds': {'northeast': {'lat': 35.4056304, 'lng': 139.5369436},
   'southwest': {'lat': 35.4002057, 'lng': 139.5186068}},
  'copyrights': '地図データ ©2016 Google, ZENRIN',
  'legs': [{'distance': {'text': '2.7 km', 'value': 2716},
    'duration': {'text': '11分', 'value': 673},
    'end_address': '日本, 〒245-0014 神奈川県横浜市泉区中田南１丁目１ 踊場駅',
    'end_location': {'lat': 35.4056304, 'lng': 139.5186068},
    'start_address': '日本, 〒244-0003 神奈川県横浜市戸塚区戸塚町 戸塚駅',
    'start_location': {'lat': 35.40064770000001, 'lng': 139.5346506},
    'steps': [{'distance': {'text': '91 m', 'value': 91},
      'duration': {'text': '1分', 'value': 33},
      'end_location': {'lat': 35.401141, 'lng': 139.5350348},
      'html_instructions': '<b>県道203号線</b>に向かって<b>北</b>に進む',
      'polyline': {'points': 'aeawEqzsrYmAVScB'},
      'start_location': {'lat': 35.40064770000001, 'lng': 139.5346506},
      'travel_mode': 'DRIVING'},
     {'distance': {'text': '0.2 km', 'value': 151},
      'duration': {'text': '2分', 'value': 114},
      'end_location': {'lat': 35.402465, 'lng': 139.5353301},
      'html_instructions': '<b>戸塚駅東口広場出口（交差点）</b> を<b>左折</b>して <b>県道203号線</b> に入る',
      'maneuver': 'turn-left',
      'polyline': {'points': 'chawE}|srYW?g@Ge@OaAWQEQE{@?'},
      'start_location': {'lat': 35.401141, 'lng': 139.5350348},
      'travel_mode': 'DRIVING'},
     {'distance': {'text': '0.4 km', 'value': 387},
      'duration': {'text': '2分', 'value': 129},
      'end_location': {'lat': 35.4052329, 'lng': 139.5365005},
      'html_instructions': '<b>戸塚駅東口入口（交差点）</b> を<b>右折</b>して <b>東海道</b>/<b>国道1号線</b> に入る',
      'maneuver': 'turn-right',
      'polyline': {'points': 'kpawEy~srYU}@Yi@U_@sAgCQQe@YSCSAU?WBQF[Lc@VWHUFW@Q@_@@M?MBODKB'},
      'start_location': {'lat': 35.402465, 'lng': 139.5353301},
      'travel_mode': 'DRIVING'},
     {'distance': {'text': '0.6 km', 'value': 607},
      'duration': {'text': '1分', 'value': 87},
      'end_location': {'lat': 35.401252, 'lng': 139.5320803},
      'html_instructions': '<b>矢部団地入口（交差点）</b> で大きく<b>左方向</b>に曲がる',
      'maneuver': 'turn-sharp-left',
      'polyline': {'points': 'uabwEcftrYt@d@~@n@NL~AbAJJ`Ar@TTRPNVPVRXR`@vDtHJPR\\NXTVTVRPJHXPd@X'},
      'start_location': {'lat': 35.4052329, 'lng': 139.5365005},
      'travel_mode': 'DRIVING'},
     {'distance': {'text': '0.1 km', 'value': 130},
      'duration': {'text': '1分', 'value': 60},
      'end_location': {'lat': 35.4002057, 'lng': 139.5314439},
      'html_instructions': '<b>清源院入口（交差点）</b>で<b>東海道</b>/<b>国道1号線</b>へ進む',
      'polyline': {'points': 'yhawEojsrYt@`@jAn@lAl@'},
      'start_location': {'lat': 35.401252, 'lng': 139.5320803},
      'travel_mode': 'DRIVING'},
     {'distance': {'text': '1.4 km', 'value': 1350},
      'duration': {'text': '4分', 'value': 250},
      'end_location': {'lat': 35.4056304, 'lng': 139.5186068},
      'html_instructions': '<b>バスセンター前（交差点）</b> を<b>右折</b>して <b>長後街道</b>/<b>県道22号線</b> に入る<div style="font-size:0.9em">目的地は前方右側です</div>',
      'maneuver': 'turn-right',
      'polyline': {'points': 'ibawEofsrYQ`@MT]l@c@v@KREVCTCj@QdDEhCAdA?h@AZ?`@Gv@GdASnAYhAi@hAeAbBk@h@[Zq@z@[f@EFWj@y@xBQh@e@nAERo@pBEHKXQn@]bASh@k@lB}@fCa@|@W`@g@z@g@~@k@x@ED]h@'},
      'start_location': {'lat': 35.4002057, 'lng': 139.5314439},
      'travel_mode': 'DRIVING'}],
    'traffic_speed_entry': [],
    'via_waypoint': []}],
  'overview_polyline': {'points': 'aeawEqzsrYmAVScB_AGkCs@{@?U}@o@iAsAgCQQe@YSCi@Ai@J_Ad@m@PwAD]HKBt@d@nA|@jBnAvAhAb@h@d@p@jEvI^n@d@p@h@h@d@ZzAz@xC|AaB|CKREVG`AQdDEhCAnBA|@O|BSnAYhAi@hAeAbBgAdAmAbB]r@kAbDaB~EoAvDiBtFy@~AoAzBq@~@]h@'},
  'summary': '長後街道/県道22号線',
  'warnings': [],
  'waypoint_order': []}]
```

情報の取得ができた。
次回は、ルート情報から、標高を出して表示する予定です。


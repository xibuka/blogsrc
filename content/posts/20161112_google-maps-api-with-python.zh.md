---
title: 用 Python 调用 Google Maps API
date: 2016-11-12 01:22:46
tags:
- Python
---
用 Python 调用 Google Maps API 做了下路线查询。

用到的模块是 [googlemaps/google-maps-services-python](https://github.com/googlemaps/google-maps-services-python)

环境搭建直接用如下命令，顺便也可以装下 ipython。

```bash
pip install googlemaps
pip install ipython
```

另外需要申请 Google 的 API Key，在 [Google APIs](https://console.developers.google.com/apis/dashboard) 申请并启用即可。

到这里没问题的话，马上试用一下。
以"户冢站"到"踊场站"的驾车路线为例获取路线信息。

```bash
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

In [3]: directions_result = gmaps.directions('户冢站','踊场站',mode="driving",alternatives=False,language="ja")

In [4]: directions_result
Out[4]: 
[{'bounds': {'northeast': {'lat': 35.4056304, 'lng': 139.5369436},
   'southwest': {'lat': 35.4002057, 'lng': 139.5186068}},
  'copyrights': '地图数据 ©2016 Google, ZENRIN',
  'legs': [{'distance': {'text': '2.7 km', 'value': 2716},
    'duration': {'text': '11分钟', 'value': 673},
    'end_address': '日本, 〒245-0014 神奈川县横滨市泉区中田南1丁目1 踊场站',
    'end_location': {'lat': 35.4056304, 'lng': 139.5186068},
    'start_address': '日本, 〒244-0003 神奈川县横滨市户冢区户冢町 户冢站',
    'start_location': {'lat': 35.40064770000001, 'lng': 139.5346506},
    'steps': [{'distance': {'text': '91米', 'value': 91},
      'duration': {'text': '1分钟', 'value': 33},
      'end_location': {'lat': 35.401141, 'lng': 139.5350348},
      'html_instructions': '向<b>北</b>前往<b>县道203号线</b>',
      'polyline': {'points': 'aeawEqzsrYmAVScB'},
      'start_location': {'lat': 35.40064770000001, 'lng': 139.5346506},
      'travel_mode': 'DRIVING'},
     {'distance': {'text': '0.2公里', 'value': 151},
      'duration': {'text': '2分钟', 'value': 114},
      'end_location': {'lat': 35.402465, 'lng': 139.5353301},
      'html_instructions': '在<b>户冢站东口广场路口</b>向<b>左转</b>进入<b>县道203号线</b>',
      'maneuver': 'turn-left',
      'polyline': {'points': 'chawE}|srYW?g@Ge@OaAWQEQE{@?'},
      'start_location': {'lat': 35.401141, 'lng': 139.5350348},
      'travel_mode': 'DRIVING'},
     {'distance': {'text': '0.4公里', 'value': 387},
      'duration': {'text': '2分钟', 'value': 129},
      'end_location': {'lat': 35.4052329, 'lng': 139.5365005},
      'html_instructions': '在<b>户冢站东口入口路口</b>向<b>右转</b>进入<b>东海道</b>/<b>国道1号线</b>',
      'maneuver': 'turn-right',
      'polyline': {'points': 'kpawEy~srYU}@Yi@U_@sAgCQQe@YSCSAU?WBQF[Lc@VWHUFW@Q@_@@M?MBODKB'},
      'start_location': {'lat': 35.402465, 'lng': 139.5353301},
      'travel_mode': 'DRIVING'},
     {'distance': {'text': '0.6公里', 'value': 607},
      'duration': {'text': '1分钟', 'value': 87},
      'end_location': {'lat': 35.401252, 'lng': 139.5320803},
      'html_instructions': '在<b>矢部团地入口路口</b>大幅<b>左转</b>',
      'maneuver': 'turn-sharp-left',
      'polyline': {'points': 'uabwEcftrYt@d@~@n@NL~AbAJJ`Ar@TTRPNVPVRXR`@vDtHJPR\NXTVTVRPJHXPd@X'},
      'start_location': {'lat': 35.4052329, 'lng': 139.5365005},
      'travel_mode': 'DRIVING'},
     {'distance': {'text': '0.1公里', 'value': 130},
      'duration': {'text': '1分钟', 'value': 60},
      'end_location': {'lat': 35.4002057, 'lng': 139.5314439},
      'html_instructions': '在<b>清源院入口路口</b>继续沿<b>东海道</b>/<b>国道1号线</b>前行',
      'polyline': {'points': 'yhawEojsrYt@`@jAn@lAl@'},
      'start_location': {'lat': 35.401252, 'lng': 139.5320803},
      'travel_mode': 'DRIVING'},
     {'distance': {'text': '1.4公里', 'value': 1350},
      'duration': {'text': '4分钟', 'value': 250},
      'end_location': {'lat': 35.4056304, 'lng': 139.5186068},
      'html_instructions': '在<b>巴士中心前路口</b>向<b>右转</b>进入<b>长后街道</b>/<b>县道22号线</b><div style="font-size:0.9em">目的地在前方右侧</div>',
      'maneuver': 'turn-right',
      'polyline': {'points': 'ibawEofsrYQ`@MT]l@c@v@KREVCTCj@QdDEhCAdA?h@AZ?`@Gv@GdASnAYhAi@hAeAbBgAdAmAbB]r@kAbDaB~EoAvDiBtFy@~AoAzBq@~@]h@'},
      'start_location': {'lat': 35.4002057, 'lng': 139.5314439},
      'travel_mode': 'DRIVING'}],
    'traffic_speed_entry': [],
    'via_waypoint': []}],
  'overview_polyline': {'points': 'aeawEqzsrYmAVScB_AGkCs@{@?U}@o@iAsAgCQQe@YSCi@Ai@J_Ad@m@PwAD]HKBt@d@nA|@jBnAvAhAb@h@d@p@jEvI^n@d@p@h@h@d@ZzAz@xC|AaB|CKREVG`AQdDEhCAnBA|@O|BSnAYhAi@hAeAbBgAdAmAbB]r@kAbDaB~EoAvDiBtFy@~AoAzBq@~@]h@'},
  'summary': '长后街道/县道22号线',
  'warnings': [],
  'waypoint_order': []}]
```

信息获取成功。
下次准备从路线信息中提取并显示海拔。

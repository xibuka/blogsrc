---
title: Using Google Maps API with Python
date: 2016-11-12 01:22:46
tags:
- Python
---
I tried using the Google Maps API in Python to perform route search.

The module used is [googlemaps/google-maps-services-python](https://github.com/googlemaps/google-maps-services-python)

You can set up the environment with the following commands. While you're at it, also install ipython.

```bash
pip install googlemaps
pip install ipython
```

You also need to apply for a Google API key, so go to [Google APIs](https://console.developers.google.com/apis/dashboard) to apply and enable it.

If everything is fine up to this point, let's try it out right away.
Get route information by car from Totsuka Station to Odoriba Station.

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

In [3]: directions_result = gmaps.directions('Totsuka Station','Odoriba Station',mode="driving",alternatives=False,language="ja")

In [4]: directions_result
Out[4]: 
[{'bounds': {'northeast': {'lat': 35.4056304, 'lng': 139.5369436},
   'southwest': {'lat': 35.4002057, 'lng': 139.5186068}},
  'copyrights': 'Map data ©2016 Google, ZENRIN',
  'legs': [{'distance': {'text': '2.7 km', 'value': 2716},
    'duration': {'text': '11 min', 'value': 673},
    'end_address': 'Japan, 〒245-0014 Kanagawa, Yokohama, Izumi Ward, Nakataminami 1 Chome−1 Odoriba Station',
    'end_location': {'lat': 35.4056304, 'lng': 139.5186068},
    'start_address': 'Japan, 〒244-0003 Kanagawa, Yokohama, Totsuka Ward, Totsukacho Totsuka Station',
    'start_location': {'lat': 35.40064770000001, 'lng': 139.5346506},
    'steps': [{'distance': {'text': '91 m', 'value': 91},
      'duration': {'text': '1 min', 'value': 33},
      'end_location': {'lat': 35.401141, 'lng': 139.5350348},
      'html_instructions': 'Head <b>north</b> toward <b>Prefectural Route 203</b>',
      'polyline': {'points': 'aeawEqzsrYmAVScB'},
      'start_location': {'lat': 35.40064770000001, 'lng': 139.5346506},
      'travel_mode': 'DRIVING'},
     {'distance': {'text': '0.2 km', 'value': 151},
      'duration': {'text': '2 min', 'value': 114},
      'end_location': {'lat': 35.402465, 'lng': 139.5353301},
      'html_instructions': 'Turn <b>left</b> at <b>Totsuka Station East Exit Square Intersection</b> onto <b>Prefectural Route 203</b>',
      'maneuver': 'turn-left',
      'polyline': {'points': 'chawE}|srYW?g@Ge@OaAWQEQE{@?'},
      'start_location': {'lat': 35.401141, 'lng': 139.5350348},
      'travel_mode': 'DRIVING'},
     {'distance': {'text': '0.4 km', 'value': 387},
      'duration': {'text': '2 min', 'value': 129},
      'end_location': {'lat': 35.4052329, 'lng': 139.5365005},
      'html_instructions': 'Turn <b>right</b> at <b>Totsuka Station East Entrance Intersection</b> onto <b>Tokaido</b>/<b>National Route 1</b>',
      'maneuver': 'turn-right',
      'polyline': {'points': 'kpawEy~srYU}@Yi@U_@sAgCQQe@YSCSAU?WBQF[Lc@VWHUFW@Q@_@@M?MBODKB'},
      'start_location': {'lat': 35.402465, 'lng': 139.5353301},
      'travel_mode': 'DRIVING'},
     {'distance': {'text': '0.6 km', 'value': 607},
      'duration': {'text': '1 min', 'value': 87},
      'end_location': {'lat': 35.401252, 'lng': 139.5320803},
      'html_instructions': 'Make a sharp <b>left</b> at <b>Yabe Danchi Entrance Intersection</b>',
      'maneuver': 'turn-sharp-left',
      'polyline': {'points': 'uabwEcftrYt@d@~@n@NL~AbAJJ`Ar@TTRPNVPVRXR`@vDtHJPR\NXTVTVRPJHXPd@X'},
      'start_location': {'lat': 35.4052329, 'lng': 139.5365005},
      'travel_mode': 'DRIVING'},
     {'distance': {'text': '0.1 km', 'value': 130},
      'duration': {'text': '1 min', 'value': 60},
      'end_location': {'lat': 35.4002057, 'lng': 139.5314439},
      'html_instructions': 'Continue onto <b>Tokaido</b>/<b>National Route 1</b> at <b>Seigenin Entrance Intersection</b>',
      'polyline': {'points': 'yhawEojsrYt@`@jAn@lAl@'},
      'start_location': {'lat': 35.401252, 'lng': 139.5320803},
      'travel_mode': 'DRIVING'},
     {'distance': {'text': '1.4 km', 'value': 1350},
      'duration': {'text': '4 min', 'value': 250},
      'end_location': {'lat': 35.4056304, 'lng': 139.5186068},
      'html_instructions': 'Turn <b>right</b> at <b>Bus Center-mae Intersection</b> onto <b>Chogo Kaido</b>/<b>Prefectural Route 22</b><div style="font-size:0.9em">Your destination will be on the right</div>',
      'maneuver': 'turn-right',
      'polyline': {'points': 'ibawEofsrYQ`@MT]l@c@v@KREVCTCj@QdDEhCAdA?h@AZ?`@Gv@GdASnAYhAi@hAeAbBgAdAmAbB]r@kAbDaB~EoAvDiBtFy@~AoAzBq@~@]h@'},
      'start_location': {'lat': 35.4002057, 'lng': 139.5314439},
      'travel_mode': 'DRIVING'}],
    'traffic_speed_entry': [],
    'via_waypoint': []}],
  'overview_polyline': {'points': 'aeawEqzsrYmAVScB_AGkCs@{@?U}@o@iAsAgCQQe@YSCi@Ai@J_Ad@m@PwAD]HKBt@d@nA|@jBnAvAhAb@h@d@p@jEvI^n@d@p@h@h@d@ZzAz@xC|AaB|CKREVG`AQdDEhCAnBA|@O|BSnAYhAi@hAeAbBgAdAmAbB]r@kAbDaB~EoAvDiBtFy@~AoAzBq@~@]h@'},
  'summary': 'Chogo Kaido/Prefectural Route 22',
  'warnings': [],
  'waypoint_order': []}]
```

Successfully retrieved the information.
Next time, I plan to display elevation information from the route data.

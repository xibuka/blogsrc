---
title: Notes on Displaying Google Maps on iPhone
date: 2016-11-01 01:16:21
tags:
 - GoogleMap
 - iOS
---
Here are some issues I encountered when trying to display Google Maps on an iPhone.

Referring to [Google Maps API > For iOS > Maps SDK for iOS](https://developers.google.com/maps/documentation/ios-sdk/start?hl=en#google_maps_sdk), I tried to display Google Maps on the screen, but the screen was completely white and nothing appeared.

The following error message appeared in the console:

```sh
ClientParametersRequest failed, 0 attempts remaining (0 vs 6). Error Domain=com.google.HTTPStatus Code=400
```

After searching online, I found this [site](http://www.byteblocks.com/Post/ClientParametersRequest-failed-error-with-Google-Maps-SDK).
In my case, the third check revealed that my API key was "invalid".

The cause of this error is usually some mistake in the API key settings. Please check the following points:

- When generating the API key, it's better to set the bundle ID of your Xcode project. Google says this parameter is "optional," but it's safer to set it.
- If you change your app's Bundle ID, be sure to regenerate the API key.
- Make sure that "Google Maps SDK for iOS" is enabled in the Google Developers dashboard. By default, it is disabled. (This was the issue in my case)

If I have time, I plan to upload a screenshot of the API key enabled screen as well.

---
title: Desktop Notifier by Python
date: 2017-07-28 16:37:40
tags:
- Python
---
This article show how to send desktop notice using Python

![simpleNotification](/img/simpleNotification.png)

## Install requirments

we need to install `notify2` by pip

```sh
$ pip install notify2
Collecting notify2
  Downloading notify2-0.3.1-py2.py3-none-any.whl
Installing collected packages: notify2
Successfully installed notify2-0.3.1
```

## Coding

First we need to import notify2

```python
import notify2
```

Then need to initialise the d-bus connection.
D-Bus is a message bus system, a simple way for applications to talk to one another.

```python
# initialise the d-bus connection
notify2.init("hello")
```

Next we need to create a Notification object.
The simplest way is

```python
n = notify2.Notification(None)
```

else, you can add a icon to the notification.

```python
n = notify2.Notification(None, icon = "/home/wenshi/Pictures/me.jpg")
```

next, set the urgency level for the notification.

```python
n.set_urgency(notify2.URGENCY_NORMAL)
```

the other available options are

```python
notify2.URGENCY_LOW
notify2.URGENCY_NORMAL
notify2.URGENCY_CRITICAL
```

next, you can decide how long will the notification will display.
use `set_timeout` to set the time in milliseconds.

```python
n.set_timeout(5000)
```

next, file the title and message body of the notification

```python
n.update("hello title", "hello messages")
```

notification will be shown on screen by `show` method.

```python
n.show()
```

## Try it

```python
import notify2

# initialise the d-bus connection
notify2.init("hello")

# create Notification object
n = notify2.Notification(None, icon = "/path/to/your/image")

# set urgency level
n.set_urgency(notify2.URGENCY_NORMAL)

# set timeout for a notification
n.set_timeout(5000)

# update notification data for Notification object
n.update("hello title", "hello messages")

# show notification on screen
n.show()
```

and it will show up in your screen
![simpleNotification](https://raw.githubusercontent.com/xibuka/git_pics/master/simpleNotification.png)

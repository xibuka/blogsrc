---
title: '[VIM] Use built in Spell Check'
date: 2017-06-26 16:37:57
tags:
- VIM
---
From version 7, VIM has a built in spell check function, but disable by default.

## Enable/Disable

You can use `:set spell` and `:set nospell` to enable and disable it. The spell check isn't only for English, use ``` :echo &spelllang ``` to confirm the current target langurage. Use``` :set spelllang=en_GB.UTF-8 ``` to change the target langurage, also you can use ``` set spelllang=en_us,nl,medical ``` to set it to multiple langurage.

## Spell check

Use ```]s``` to move to the next, ``` [s ``` to move to the previous spell mistake.

## Correct the mistake

Use ``` z= ``` to list the suggestions of the spell mistake, and input a number
to select.

For some special work, use ``` zg ``` to add it as user work. And use ``` zw ``` to delete it.

## summary

| command      | action     |
| ------------ | ---------- |
| :set spell   | enable spell check |
| :set nospell | disable spell check |
| ]s           | move to the next mistake |
| [s           | move to the previous mistake |
| z=           | list the suggestions |
| zg           | add the word         |
| zw           | delete the word      |

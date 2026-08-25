#!/usr/bin/env bash

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x

# Toggle: If rofi is already open, kill it and exit
if pgrep -x "rofi" >/dev/null; then
  pkill -x "rofi"
  exit 0
fi

dir="$HOME/.config/rofi/launchers/type-6"
theme='style-1'

## Run
rofi \
  -show drun \
  -theme ${dir}/${theme}.rasi

#!/bin/bash

# Get the current ASUS profile
CURRENT=$(asusctl profile -g | grep 'Active profile' | cut -d' ' -f3)

if [ "$CURRENT" = "Quiet" ]; then
  asusctl profile set Balanced
  notify-send "Profile: Balanced" "CPU: Snappy | Fans: Smart" -i balanced-profile
elif [ "$CURRENT" = "Balanced" ]; then
  asusctl profile set Performance
  notify-send "Profile: Performance" "CPU: Max | Fans: Aggressive" -i performance-profile
else
  asusctl profile set Quiet
  notify-send "Profile: Quiet" "CPU: Low | Fans: Silent" -i battery-low
fi

##!/bin/bash
#CURRENT=$(powerprofilesctl get)
#
#if [ "$CURRENT" = "power-saver" ]; then
#  powerprofilesctl set balanced
#  # hyprctl keyword monitor eDP-1,2880x1800@60,0x0,1.5
#  notify-send "Mode: Balanced" "CPU: Balanced" -i balanced-profile
#elif [ "$CURRENT" = "balanced" ]; then
#  powerprofilesctl set performance
#  # hyprctl keyword monitor eDP-1,2880x1800@90,0x0,1.5
#  notify-send "Mode: Performance" "CPU: High" -i performance-profile
#else
#  powerprofilesctl set power-saver
#  # hyprctl keyword monitor eDP-1,2880x1800@60,0x0,1.5
#  notify-send "Mode: Power Save" "CPU: Low" -i battery-low
#fi

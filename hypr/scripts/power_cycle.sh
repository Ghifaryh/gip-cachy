#!/bin/bash
CURRENT=$(powerprofilesctl get)

if [ "$CURRENT" = "power-saver" ]; then
  powerprofilesctl set balanced
  # hyprctl keyword monitor eDP-1,2880x1800@60,0x0,1.5
  notify-send "Mode: Balanced" "CPU: Balanced" -i balanced-profile
elif [ "$CURRENT" = "balanced" ]; then
  powerprofilesctl set performance
  # hyprctl keyword monitor eDP-1,2880x1800@90,0x0,1.5
  notify-send "Mode: Performance" "CPU: High" -i performance-profile
else
  powerprofilesctl set power-saver
  # hyprctl keyword monitor eDP-1,2880x1800@60,0x0,1.5
  notify-send "Mode: Power Save" "CPU: Low" -i battery-low
fi

#!/bin/bash

# Use hyprctl to get the current refresh rate and round it to an integer
# We use jq (which you should have) for more reliable parsing
CURRENT_HZ=$(hyprctl monitors -j | jq '.[] | select(.name == "eDP-1") | .refreshRate' | cut -d'.' -f1)

# If CURRENT_HZ is empty (happens if jq fails), fallback to the old grep method
if [ -z "$CURRENT_HZ" ]; then
    CURRENT_HZ=$(hyprctl monitors | grep -A 1 "eDP-1" | grep "@" | awk '{print $2}' | cut -d'.' -f1)
fi

# Logic: If it's 61 or higher, drop to 60. Otherwise, go to 90.
if [ "$CURRENT_HZ" -gt 60 ]; then
    hyprctl keyword monitor eDP-1,2880x1800@60,0x0,1.5
    notify-send -h string:x-canonical-private-synchronous:sys-notify -u low "Display" "Refresh Rate: 60Hz (Battery Saver)" -i display
else
    hyprctl keyword monitor eDP-1,2880x1800@90,0x0,1.5
    notify-send -h string:x-canonical-private-synchronous:sys-notify -u low "Display" "Refresh Rate: 90Hz (Smooth Performance)" -i display
fi

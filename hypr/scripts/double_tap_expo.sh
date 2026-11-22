#!/usr/bin/env bash
TAP_FILE="/tmp/super_tap"

if [ -f "$TAP_FILE" ]; then
  rm "$TAP_FILE"
  hyprctl dispatch hyprexpo:expo toggle
else
  touch "$TAP_FILE"
  sleep 0.3
  rm -f "$TAP_FILE"
fi

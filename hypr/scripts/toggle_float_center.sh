#!/usr/bin/env bash
hyprctl dispatch togglefloating
sleep 0.05
hyprctl dispatch resizeactive exact 1600 1000
hyprctl dispatch centerwindow

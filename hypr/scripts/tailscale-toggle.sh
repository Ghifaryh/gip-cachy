#!/usr/bin/env bash

BACKEND_STATE=$(tailscale status --json 2>/dev/null | jq -r '.BackendState // empty')

if [ "$BACKEND_STATE" = "Running" ]; then
  tailscale down
  notify-send "Tailscale" "Service stopped (OFF)" -i network-vpn
else
  tailscale up
  notify-send "Tailscale" "Service started (ON)" -i network-vpn
fi

pkill -RTMIN+8 waybar

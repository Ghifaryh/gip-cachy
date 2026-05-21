#!/bin/bash

# Get the status
if status=$(tailscale status --active 2>/dev/null | head -n 1); then
  # Get your Tailscale IP for the tooltip
  ip=$(tailscale ip -4)
  echo "{\"text\": \"󱠾\", \"tooltip\": \"Connected: $ip\", \"class\": \"connected\"}"
else
  echo "{\"text\": \"󱠾\", \"tooltip\": \"Tailscale Offline\", \"class\": \"disconnected\"}"
fi

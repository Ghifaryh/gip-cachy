#!/usr/bin/env bash

# 1. Check openfortivpn process
FORTI_ACTIVE=0
pgrep openfortivpn >/dev/null && FORTI_ACTIVE=1

# 2. Check Tailscale status and backend state
STATUS_JSON=$(tailscale status --json 2>/dev/null)
BACKEND_STATE=$(echo "$STATUS_JSON" | jq -r '.BackendState // "Stopped"')

EXIT_NODE_NAME=""
if [ "$BACKEND_STATE" = "Running" ]; then
  EXIT_NODE_ID=$(echo "$STATUS_JSON" | jq -r '.ExitNodeStatus.ID // empty')
  if [ -n "$EXIT_NODE_ID" ]; then
    EXIT_NODE_NAME=$(echo "$STATUS_JSON" | jq -r --arg id "$EXIT_NODE_ID" '.Peer[] | select(.ID == $id) | .HostName')
  fi
fi

# 3. Format Waybar JSON output
ICONS=()
TOOLTIPS=()
CLASSES=()

if [ "$FORTI_ACTIVE" -eq 1 ]; then
  ICONS+=("󰒄")
  TOOLTIPS+=("FortiVPN: Connected")
  CLASSES+=("forti-active")
fi

if [ "$BACKEND_STATE" = "Running" ]; then
  if [ -n "$EXIT_NODE_NAME" ]; then
    ICONS+=("󰖂")
    TOOLTIPS+=("Tailscale: Exit Node ($EXIT_NODE_NAME)")
    CLASSES+=("exit-node")
  else
    ICONS+=("󰖂")
    TOOLTIPS+=("Tailscale: Direct")
    CLASSES+=("ts-direct")
  fi
else
  ICONS+=("󰖂")
  TOOLTIPS+=("Tailscale: Stopped")
  CLASSES+=("ts-offline")
fi

TEXT=$(
  IFS=" "
  echo "${ICONS[*]}"
)
TOOLTIP=$(
  IFS=" | "
  echo "${TOOLTIPS[*]}"
)
CLASS_STR=$(
  IFS=" "
  echo "${CLASSES[*]}"
)

echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"$CLASS_STR\"}"

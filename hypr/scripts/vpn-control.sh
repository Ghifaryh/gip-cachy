#!/usr/bin/env bash

ACTION="$1"

notify_vpn() {
  local title="$1"
  local body="$2"
  local icon="${3:-network-vpn}"
  local timeout="${4:-3000}"

  notify-send \
    -t "$timeout" \
    -i "$icon" \
    -h "boolean:transient:true" \
    -h "string:x-canonical-private-synchronous:vpn_notif" \
    "$title" "$body"
}

case "$ACTION" in
"ts-toggle")
  if tailscale status >/dev/null 2>&1; then
    if ERR=$(sudo tailscale down 2>&1); then
      notify_vpn "Tailscale" "Service stopped (OFF)" "network-vpn" 2500
    else
      notify_vpn "Tailscale Error" "$ERR" "dialog-error" 5000
    fi
  else
    # Plain 'tailscale up' without flags restores connection without conflict
    if ERR=$(sudo tailscale up 2>&1); then
      notify_vpn "Tailscale" "Service started (ON)" "network-vpn" 2500
    else
      notify_vpn "Tailscale Error" "$ERR" "dialog-error" 5000
    fi
  fi
  ;;

"ts-aio")
  tailscale status >/dev/null 2>&1 || sudo tailscale up >/dev/null 2>&1
  notify_vpn "Tailscale" "Connecting to gip-wrk-aio..." "network-vpn" 2500

  if ERR=$(sudo tailscale set --exit-node=gip-wrk-aio --exit-node-allow-lan-access --accept-routes 2>&1); then
    notify_vpn "Tailscale" "Active exit node: gip-wrk-aio" "network-vpn" 3000
  else
    notify_vpn "Exit Node Error" "$ERR" "dialog-error" 5000
  fi
  ;;

"ts-sandbox")
  tailscale status >/dev/null 2>&1 || sudo tailscale up >/dev/null 2>&1
  notify_vpn "Tailscale" "Connecting to gip-wrk-sandbox..." "network-vpn" 2500

  if ERR=$(sudo tailscale set --exit-node=gip-wrk-sandbox --exit-node-allow-lan-access --accept-routes 2>&1); then
    notify_vpn "Tailscale" "Active exit node: gip-wrk-sandbox" "network-vpn" 3000
  else
    notify_vpn "Exit Node Error" "$ERR" "dialog-error" 5000
  fi
  ;;

"ts-direct")
  if ERR=$(sudo tailscale set --exit-node="" 2>&1); then
    notify_vpn "Tailscale" "Exit node cleared (Direct)" "network-vpn" 2500
  else
    notify_vpn "Tailscale Error" "$ERR" "dialog-error" 5000
  fi
  ;;

"disconnect-all")
  # Clear exit node before bringing down so state stays clean
  if tailscale status >/dev/null 2>&1; then
    sudo tailscale set --exit-node="" 2>/dev/null
  fi
  sudo tailscale down 2>/dev/null
  sudo pkill -SIGTERM openfortivpn 2>/dev/null
  notify_vpn "VPN" "All connections terminated." "network-vpn" 2500
  ;;

*)
  echo "Usage: $0 {ts-toggle|ts-aio|ts-sandbox|ts-direct|disconnect-all}"
  exit 1
  ;;
esac

pkill -RTMIN+8 waybar

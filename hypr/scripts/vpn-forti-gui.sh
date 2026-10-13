#!/usr/bin/env bash

# Check if already running
if pgrep openfortivpn >/dev/null; then
  notify-send "FortiVPN" "Already connected!" -i network-vpn
  exit 0
fi

# Pop up a clean GUI input box for the email OTP
OTP=$(zenity --entry --title="FortiVPN 2FA" --text="Enter Gmail OTP Code:" --hide-text)

if [ -z "$OTP" ]; then
  notify-send "FortiVPN" "Connection cancelled." -i dialog-warning
  exit 1
fi

# Pipe the OTP into openfortivpn in the background
sudo openfortivpn -c /etc/openfortivpn/pssn.conf --otp="$OTP" &

sleep 2
pkill -RTMIN+8 waybar
notify-send "FortiVPN" "Connected to PSSN." -i network-vpn

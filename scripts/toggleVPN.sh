#!/usr/bin/env sh

export STATUS_FILE="$XDG_RUNTIME_DIR/VPN.status"

enable_vpn() {
    printf "true" >"$STATUS_FILE"
    notify-send -u normal "Enabling Headscale VPN"
    # sudo systemctl start wg-quick-wg0.service
    tailscale up
}

disable_vpn() {
    printf "false" >"$STATUS_FILE"
    notify-send -u normal "Disabling Headscale VPN"
    # sudo systemctl stop wg-quick-wg0.service
    tailscale down
}

if ! [ -f "$STATUS_FILE" ]; then
  enable_vpn
else
  if [ $(cat "$STATUS_FILE") = "true" ]; then
    disable_vpn
  elif [ $(cat "$STATUS_FILE") = "false" ]; then
    enable_vpn
  else
    enable_vpn
  fi
fi

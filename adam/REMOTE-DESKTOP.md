# Adam's desktop from Michael

This shares the **already logged-in** Hyprland desktop. It does not enable
automatic login, create a virtual monitor, or expose a login screen remotely.

## Configuration

- Adam: Sunshine is a user service following the UWSM graphical session. WLR
  capture needs no `CAP_SYS_ADMIN`; the pinned Sunshine package has CUDA enabled
  only for its NVIDIA/NVENC build. Adam's Hyprland startup runs `uwsm finalize`
  to export the Wayland environment and release UWSM's session-service gate.
- Michael: Moonlight Qt and the `moonlight-adam` launcher are installed through
  Home Manager. The launcher uses 1920x1080, 60 FPS, 20 Mbps, absolute mouse mode,
  and system-key capture in fullscreen mode. Use the Moonlight GUI for other
  resolutions or bitrates.
- Transport: Adam's existing WireGuard address is `10.255.255.61`; Michael's is
  `10.255.255.2`. Both need their existing `wg0` connections active, and the VPN
  hub must allow traffic between these peers and preserve Michael's source IP.
- Sunshine binds IPv4 to `10.255.255.61`, with UPnP disabled. Its default TCP
  ports (47984, 47989, 47990, 48010) and UDP ports (47998, 47999, 48000, 48002,
  48010) are restricted to Michael (`10.255.255.2` via `wg0`) before Adam's existing broad
  firewall accepts. Other services' firewall rules are unchanged. The rules
  explicitly require Adam's current iptables firewall backend. Manage the Web UI
  from Michael; neither other VPN peers nor local loopback clients are exempted,
  including during first administrator enrollment.

## Apply

Apply Adam's NixOS and Home Manager configurations, and Michael's Home Manager
configuration. When using a Git flake, newly added source files must first be
tracked by Git; no commit or lockfile update is necessary.

From this repository on Adam:

```sh
sudo nixos-rebuild switch --flake ./adam#host
home-manager switch --flake ./adam#home
```

From the corresponding checkout on Michael:

```sh
home-manager switch --flake ./michael#home
```

After applying Adam's settings, log out and log in through greetd again so that
the desktop runs under UWSM. A compositor output must be active; monitor-off,
screen locking, or suspend can interrupt capture. Unlock Adam locally if needed;
this setup does not bypass the screen lock.

## Pair and connect

1. On Adam, check the service inside the logged-in desktop session:
   `systemctl --user status sunshine`.
2. On Michael, open `https://10.255.255.61:47990`. Sunshine uses a self-signed
   certificate by default; confirm this is your VPN host before accepting it.
   Create the Sunshine administrator credentials on first use.
3. Run `moonlight-adam pair` on Michael and enter the displayed PIN in Sunshine's
   Web UI. Pairing and administrator credentials are runtime state, **not** Nix
   configuration and must not be committed.
4. Run `moonlight-adam`, or open Moonlight, manually add `10.255.255.61`, and
   select **Desktop**. Automatic discovery need not work over WireGuard.

`Ctrl+Alt+Shift+Q` ends the client stream; `Ctrl+Alt+Shift+Z` toggles input capture.
The shared Hyprland shortcuts are intended for Adam while the stream captures
the keyboard. If Michael still intercepts a shortcut, check Moonlight's system-key
capture and Wayland input handling; those compositor interactions require a
runtime check on Michael.

## Troubleshooting

- View server logs: `journalctl --user -u sunshine -b`.
- Inspect displays in Adam's desktop session: `hyprctl monitors all`.
- Confirm VPN routing on Michael: `ip route get 10.255.255.61` (via `wg0`).
- Confirm listening addresses on Adam: `ss -lntup`; Sunshine should use
  `10.255.255.61`, not `0.0.0.0` or `::`.
- If the VPN was unavailable when the session started, reconnect it and restart
  Sunshine: `systemctl --user restart sunshine`.

The configuration does not provide a headless fallback, automatic display-mode
switching, port forwarding, or access before Adam's desktop login.

## Configuration checks (no activation)

Run `python3 -B -m unittest discover -s tests -p test_remote_desktop.py -v`
from the repository root. If Python is not on your PATH, use the repository's
development shell:

```sh
nix develop --no-update-lock-file --command \
  python3 -B -m unittest discover -s tests -p test_remote_desktop.py -v
```

The tests evaluate the locked host/client configurations and model the
service-specific firewall rules without changing the live firewall.

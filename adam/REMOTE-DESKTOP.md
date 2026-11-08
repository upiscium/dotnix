# Adam's desktop from Michael

This shares an **already authenticated** Hyprland session on a named virtual
display. It does not enable automatic login or expose a login screen remotely.
On Proxmox, noVNC remains the text/greetd login console; the graphical desktop
is viewed with Moonlight, not through the Bochs virtual VGA.

## Configuration

- Adam: Sunshine is a user service following the UWSM graphical session. WLR
  capture needs no `CAP_SYS_ADMIN`; the pinned Sunshine package has CUDA enabled
  only for its NVIDIA/NVENC build. Adam selects only the RTX 4080 DRM card via
  `AQ_DRM_DEVICES=/dev/dri/adam-nvidia`. A PCI-specific udev rule creates this
  colon-free stable link; `card1` numbering is not assumed.
- Adam's session helper requests the `SUNSHINE` headless output (1920×1080,
  60 Hz), then finalizes UWSM even if creation fails so the session is still
  diagnosable. Sunshine selects `SUNSHINE` explicitly and starts only after
  a bounded check verifies its mode and receives one screencopy frame. The
  check discards that frame without saving an image. On failure Sunshine stops
  before starting; SSH and the VM remain available for recovery.
- This is a comparison for the observed compositor RBO/framebuffer failures,
  not a claim that rendering has been fixed before runtime verification. The
  temporary Adam debug logging remains enabled until that verification.
- Virtual mouse/keyboard injection uses `/dev/uinput`. Adam installs an early
  udev `uaccess` rule for that node, before `73-seat-late.rules`, so the active
  local session gets an ACL. The node is not world-writable and the user is not
  added to the broad `input` or permanent `uinput` group. Sunshine's startup gate
  also rejects missing write access, rather than serving a view-only session
  that cannot inject input. This is session-based access, not program isolation.
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
- The only additional trusted CSRF origin is `https://10.255.255.61:47990`.
  Keep it in sync if changing Sunshine's bind address or HTTPS port. This permits
  the direct Web UI's browser POSTs without disabling CSRF protection or broadening network
  access. Use this exact URL, not an unconfigured hostname or reverse proxy.

## Apply

Apply Adam's NixOS and Home Manager configurations, and Michael's Home Manager
configuration. When using a Git flake, newly added source files must first be
tracked by Git; no commit or lockfile update is necessary.

Before applying, record the old system and Home Manager generation paths for
recovery. Save GUI work and disconnect Moonlight. From this repository on Adam:

```sh
readlink -f /run/current-system
readlink -f ~/.local/state/nix/profiles/home-manager
uwsm stop
sudo nixos-rebuild switch --flake ./adam#host
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=drm --action=change
sudo udevadm trigger --subsystem-match=misc --sysname-match=uinput --action=change
sudo udevadm settle
readlink -f /dev/dri/adam-nvidia
home-manager switch --flake ./adam#home
systemctl --user daemon-reload
```

**Do not log in with the new configuration if `/dev/dri/adam-nvidia` is absent
or points to the Bochs card.** Inspect it with
`udevadm info --query=property --name=/dev/dri/adam-nvidia`; `ID_PATH` must be
`pci-0000:01:00.0`. The current VM mapping resolves to `/dev/dri/card1`, but that
number may change. The saved Home Manager generation is needed if activation
succeeds but the new session fails.

From the corresponding checkout on Michael:

```sh
home-manager switch --flake ./michael#home
```

After applying Adam's settings, log in through greetd again so that
the desktop runs under UWSM with the new startup-only GPU selection. `SUNSHINE`
must appear in `hyprctl -i 0 monitors all`; a Bochs-only `Virtual-1` is not the
intended new configuration. A compositor output must be active; monitor-off,
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

## Mouse and keyboard capture

If the remote cursor follows the Proxmox console but not Moonlight, first check
that Sunshine has access to `/dev/uinput` and its virtual input devices appear
in `hyprctl -i 0 devices`. After changing the rule, reload/trigger udev and
restart Sunshine while the authenticated graphical session is active:

```sh
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=misc --sysname-match=uinput --action=change
sudo udevadm settle
nix shell --inputs-from ./adam nixpkgs#acl --command getfacl -p /dev/uinput
systemctl --user daemon-reload
systemctl --user reset-failed sunshine
systemctl --user restart sunshine
```

The ACL should include the active `upiscium` user with `rw-`. Do not work around
this using `chmod 666 /dev/uinput`, `CAP_SYS_ADMIN`, or the physical `input` group.

On Michael, CLI flags do not apply when launching the Moonlight GUI separately.
For a one-run native Wayland/system-shortcut capture test, disconnect the existing
stream and run in Michael's graphical session:

```sh
QT_QPA_PLATFORM=wayland moonlight stream \
  --resolution 1920x1080 --fps 60 --bitrate 20000 \
  --absolute-mouse --capture-system-keys always --display-mode borderless \
  10.255.255.61 Desktop
```

Focus the stream and click inside its video region to acquire input. Moonlight's
`Ctrl+Alt+Shift+Z` toggles capture (do not toggle blindly); `Ctrl+Alt+Shift+M`
toggles absolute/relative mouse mode. System-key capture is focused-surface
scoped, not a global removal of Hyprland bindings. If Alt+Enter is still local,
inspect Michael's `binds:disable_keybind_grabbing` and the stream window's
`xwayland` status before adding any window rule; the default already allows
shortcut inhibition. Do not globally unbind the shared shortcuts.

## Troubleshooting

- View server logs: `journalctl --user -u sunshine -b`.
- Inspect displays in Adam's desktop session: `hyprctl monitors all`.
- For rendering failures, use `hyprctl -i 0 rollinglog` after a fresh login and
  inspect DRM/EGL/RBO errors. Temporary debug logs may contain window names;
  restore normal logging after diagnosis.
- If Sunshine fails its readiness check, inspect
  `journalctl --user -u sunshine -b`. A present output is not enough if its
  renderer cannot return a frame. Do not remove the gate or grant
  `CAP_SYS_ADMIN` merely to make the service report running.
- Confirm VPN routing on Michael: `ip route get 10.255.255.61` (via `wg0`).
- Confirm listening addresses on Adam: `ss -lntup`; Sunshine should use
  `10.255.255.61`, not `0.0.0.0` or `::`.
- If the VPN was unavailable when the session started, reconnect it and restart
  Sunshine: `systemctl --user restart sunshine`.
- If the Web UI reports a CSRF protection error, confirm the browser is using
  `https://10.255.255.61:47990`. After applying a changed Sunshine configuration,
  run `systemctl --user daemon-reload` and `systemctl --user restart sunshine`
  on Adam, then reload the browser page before retrying. Add another exact,
  trusted origin declaratively only if deliberately using a different URL;
  do not disable CSRF protection.

The configuration provides a virtual graphical output only **after login**. It
does not provide automatic login, dynamic client-resolution switching, port
forwarding, or access before Adam's desktop login.

## Recovery from a failed comparison

Stop the graphical session with `uwsm stop`, then activate the recorded previous
Home Manager generation using `<previous-home-manager-generation>/activate`.
If this was the most recent NixOS switch, use
`sudo nixos-rebuild switch --rollback` to restore the previous system generation,
then run `systemctl --user daemon-reload` and log in through greetd again.
Do not delete the VPN keys or Sunshine's pairing state. Reverting a generation
does not revert the working-tree source; do not reapply the comparison until
its failure is understood. Keep the CSRF/VPN access fixes when revising source.

## Configuration checks (no activation)

Run `python3 -B -m unittest discover -s tests -p test_remote_desktop.py -v`
from the repository root. If Python is not on your PATH, use the repository's
development shell:

```sh
nix develop --no-update-lock-file --command \
  python3 -B -m unittest discover -s tests -p test_remote_desktop.py -v
```

The tests evaluate the locked host/client configurations, model the
service-specific firewall rules, and build/check the small readiness shell
application. Readiness cases run with mocked IPC/capture functions and do not
touch the live desktop, capture an image, or change the live firewall.

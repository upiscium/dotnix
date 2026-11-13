{ config, pkgs, lib, ... }:
let
  port = config.services.sunshine.settings.port;
  ports = offsets: lib.concatStringsSep "," (map (offset: toString (port + offset)) offsets);
  protocols = {
    tcp = ports [ (-5) 0 1 21 ];
    udp = ports [ 9 10 11 13 21 ];
  };
  displayName = "SUNSHINE";
  uinputAccess = pkgs.writeTextFile {
    name = "adam-sunshine-uinput-access";
    destination = "/lib/udev/rules.d/70-adam-sunshine-uinput.rules";
    # Run before systemd's 73-seat-late.rules so its uaccess builtin grants
    # the active local session access. Do not grant world write or membership
    # of the broader physical-input group.
    text = ''
      SUBSYSTEM=="misc", KERNEL=="uinput", TAG+="uaccess", OPTIONS+="static_node=uinput"
    '';
  };
  displayReady = pkgs.writeShellApplication {
    name = "adam-sunshine-display-ready";
    runtimeInputs = [ config.programs.hyprland.package pkgs.coreutils pkgs.grim pkgs.jq ];
    text = ''
      if ! test -w /dev/uinput; then
        printf 'Sunshine not started: no write access to /dev/uinput for the logged-in user.\n' >&2
        exit 1
      fi
      display="${displayName}"
      monitor_ready() {
        hyprctl -j monitors | jq -e --arg name "$display" '
          any(.[]; .name == $name and .disabled == false and .dpmsStatus == true
            and .width == 1920 and .height == 1080
            and .refreshRate >= 59 and .refreshRate <= 61)
        ' > /dev/null
      }

      for ((attempt = 1; attempt <= 10; attempt++)); do
        if monitor_ready; then
          break
        fi
        printf 'Waiting for %s (attempt %s/10)\n' "$display" "$attempt" >&2
        sleep 1
      done
      if ! monitor_ready; then
        printf 'Sunshine not started: %s is not ready at 1920x1080@60.\n' "$display" >&2
        exit 1
      fi

      # A registered monitor is not sufficient: the previous broken renderer
      # advertised an output but never returned a screencopy frame. Discard the
      # test frame; do not store a desktop screenshot or inspect its contents.
      if ! timeout --kill-after=2s 10s grim -o "$display" - > /dev/null; then
        printf 'Sunshine not started: no first screencopy frame from %s.\n' "$display" >&2
        exit 1
      fi
    '';
  };
in
{
  # The PCI identity is verified on this VM. A colon-free link is required for
  # Aquamarine's colon-separated device list; do not rely on card1 numbering.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", ENV{DEVTYPE}=="drm_minor", KERNEL=="card[0-9]*", KERNELS=="0000:01:00.0", ATTRS{vendor}=="0x10de", SYMLINK+="dri/adam-nvidia"
  '';
  services.udev.packages = [ uinputAccess ];

  services.sunshine = {
    enable = true;
    autoStart = true;
    # Only Sunshine gets CUDA support; do not change the host's package inputs.
    package = pkgs.sunshine.override {
      cudaSupport = true;
      cudaPackages = pkgs.cudaPackages;
    };
    # WLR captures the logged-in Hyprland session without CAP_SYS_ADMIN.
    capSysAdmin = false;
    openFirewall = false;
    settings = {
      sunshine_name = "adam";
      address_family = "ipv4";
      bind_address = "10.255.255.61";
      port = 47989;
      capture = "wlr";
      encoder = "nvenc";
      output_name = displayName;
      upnp = "disabled";
      origin_web_ui_allowed = "lan";
      # Browser POSTs from the direct VPN Web UI need an explicit trusted origin.
      # Keep scheme, host and HTTPS port specific; do not disable CSRF protection.
      csrf_allowed_origins = "https://10.255.255.61:47990";
    };
    applications.apps = [ { name = "Desktop"; } ];
  };

  # Keep UWSM and the authenticated session usable on a failed comparison, but
  # do not launch Sunshine against an absent output or a stalled renderer.
  systemd.user.services.sunshine.serviceConfig = {
    ExecStartPre = [ (lib.getExe displayReady) ];
    TimeoutStartSec = "30s";
  };

  # Sunshine follows graphical-session.target, so launch the authenticated
  # session through UWSM rather than starting the compositor directly.
  services.greetd.settings.default_session.command = lib.mkForce
    "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --user-menu --cmd '${lib.getExe config.programs.uwsm.package} start -F -- /run/current-system/sw/bin/start-hyprland'";

  assertions = [
    {
      assertion = config.networking.firewall.enable && config.networking.firewall.backend == "iptables";
      message = "Adam's Sunshine VPN restriction requires the enabled iptables firewall; adapt the Sunshine rules before changing backends.";
    }
  ];

  # Existing global 2000-65535 accepts would otherwise expose Sunshine on
  # ens18 too. Insert only these service-specific restrictions before them.
  # Limit initial administrator enrollment as well as streams to Michael.
  # Manage the Web UI from Michael; loopback is deliberately not exempted.
  networking.firewall.extraCommands = lib.concatStrings (lib.mapAttrsToList (protocol: portList: ''
    iptables -I nixos-fw 1 ! -i wg0 -p ${protocol} -m multiport --dports ${portList} -j DROP
    iptables -I nixos-fw 1 -i wg0 ! -s 10.255.255.2/32 -p ${protocol} -m multiport --dports ${portList} -j DROP
  '') protocols);
  networking.firewall.extraStopCommands = lib.concatStrings (lib.mapAttrsToList (protocol: portList: ''
    iptables -D nixos-fw -i wg0 ! -s 10.255.255.2/32 -p ${protocol} -m multiport --dports ${portList} -j DROP 2>/dev/null || true
    iptables -D nixos-fw ! -i wg0 -p ${protocol} -m multiport --dports ${portList} -j DROP 2>/dev/null || true
  '') protocols);
}

{ config, pkgs, lib, ... }:
let
  port = config.services.sunshine.settings.port;
  ports = offsets: lib.concatStringsSep "," (map (offset: toString (port + offset)) offsets);
  protocols = {
    tcp = ports [ (-5) 0 1 21 ];
    udp = ports [ 9 10 11 13 21 ];
  };
in
{
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
      upnp = "disabled";
      origin_web_ui_allowed = "lan";
    };
    applications.apps = [ { name = "Desktop"; } ];
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

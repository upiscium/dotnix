{ lib, ... }:
let
  # Networks allowed to reach the PROJECT-SUZKA web entrypoint (Caddy :8080).
  suzkaClientNetworks = [ "10.12.0.0/16" "10.255.255.0/24" "192.168.100.0/24" ];
  suzkaPort = "8080";
  rule = action: net:
    "iptables -w ${action} nixos-fw -p tcp --dport ${suzkaPort} -s ${net} -j nixos-fw-accept";
in
{
  # Only SSH (opened by services.openssh) is reachable from everywhere;
  # PROJECT-SUZKA is reachable only from the networks above.
  networking.firewall = {
    allowedTCPPortRanges = lib.mkForce [ ];
    allowedUDPPortRanges = lib.mkForce [ ];
    extraCommands = lib.concatMapStringsSep "\n" (rule "-A") suzkaClientNetworks;
    extraStopCommands = lib.concatMapStringsSep "\n" (net: "${rule "-D" net} || true") suzkaClientNetworks;
  };

  services.avahi.openFirewall = lib.mkForce false;
}

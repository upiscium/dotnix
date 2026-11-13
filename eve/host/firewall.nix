{ lib, ... }: {
  # Only SSH (opened by services.openssh) is reachable from outside.
  # PROJECT-SUZKA listens on loopback and is used through an SSH tunnel.
  networking.firewall = {
    allowedTCPPortRanges = lib.mkForce [ ];
    allowedUDPPortRanges = lib.mkForce [ ];
  };

  services.avahi.openFirewall = lib.mkForce false;
}

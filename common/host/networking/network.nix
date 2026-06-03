{ hostname, ... }: {
  services.openssh.enable = true;
  programs.ssh.startAgent = true;
  programs.kdeconnect.enable = true;

  networking.hostName = hostname;
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  networking.nameservers = [ "192.168.100.31" "8.8.8.8" "8.8.4.4" "1.1.1.1" ]; # fallback DNS
  services.resolved.enable = true;
  networking.resolvconf.enable = false;
  # networking.networkmanager.dns = "systemd-resolved";

  services.avahi = {
    enable = true;
    openFirewall = true;
  };
}

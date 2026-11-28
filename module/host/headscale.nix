{ pkgs, ... }:{
  services.tailscale = {
    enable = true;
    openFirewall = true;            # tailscaledのUDP 41641を開ける
    useRoutingFeatures = "client";  # ルートを受ける側。不要なら "none"
  };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  environment.systemPackages = with pkgs; [ trayscale ];
}

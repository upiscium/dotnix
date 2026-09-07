{ pkgs, ... }: {
  users.users.upiscium = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "upiscium";
    extraGroups = [ "networkmanager" "wheel" "dialout" "wireshark" ];
  };
}


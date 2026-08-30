{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    opencode-discord-bridge = {
      url = "github:upiscium/DisCode";
      # url = "github:upiscium/OpencodeDiscordBridge/d7bdf912942e61cb43912fa656569ba00bdfb3da";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    let
      mkNixosSystem = (import ../utils.nix { inherit inputs; }).mkNixosSystem;
      mkHomeManagerConfiguration = (import ../utils.nix { inherit inputs; }).mkHomeManagerConfiguration;
      hostname = "Adam";
      username = "upiscium";
    in
    {
      nixosConfigurations.host = mkNixosSystem {
        system = "x86_64-linux";
        hostname = hostname;
        username = username;
        modules = [
          ./host
        ];
      };

      homeConfigurations.home = mkHomeManagerConfiguration {
        system = "x86_64-linux";
        hostname = hostname;
        username = username;
        modules = [
          ./home
        ];
      };
    };
}

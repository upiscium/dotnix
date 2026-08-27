{
  description = "dotnix repository policy, reusable packages, and development boundary";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    opencodePolicy = {
      url = "github:upiscium/OpenCodePolicy";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, opencodePolicy }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          neovim = pkgs.callPackage ./packages/neovim { };
        });

      checks = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          policy = opencodePolicy.packages.${system}.opencode-policy;
        in
        {
          neovim-package = self.packages.${system}.neovim;

          opencode-policy = pkgs.runCommand "dotnix-opencode-policy" {
            nativeBuildInputs = [ policy ];
          } ''
            opencode-policy audit-consumer \
              --profile global \
              --consumer ${self} \
              --strict
            touch "$out"
          '';
        });

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = [ opencodePolicy.packages.${system}.opencode-policy ];
        };
      });
    };
}

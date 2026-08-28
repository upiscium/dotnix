{
  description = "dotnix portable package distribution, repository policy, and development boundary";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    opencodePolicy = {
      url = "github:upiscium/OpenCodePolicy";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, opencodePolicy }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          just = pkgs.just;
          neovim = pkgs.callPackage ./packages/neovim { inherit pkgs; };
        });

      apps = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          installer = pkgs.writeShellApplication {
            name = "dotnix-install";
            runtimeInputs = [ pkgs.nix ];
            text = ''
              if [ "$#" -ne 1 ]; then
                echo "usage: dotnix-install <package>" >&2
                exit 2
              fi

              package="$1"
              exec nix profile install "path:${self.outPath}#$package"
            '';
          };
        in
        {
          install = {
            type = "app";
            program = "${installer}/bin/dotnix-install";
          };
        });

      checks = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          policy =
            if builtins.hasAttr system opencodePolicy.packages
            then opencodePolicy.packages.${system}.opencode-policy
            else null;
        in
        {
          neovim-package = self.packages.${system}.neovim;

          justfile = pkgs.runCommand "dotnix-justfile-check" {
            nativeBuildInputs = [ pkgs.just ];
          } ''
            just --justfile ${./justfile} --list > "$out"
          '';
        }
        // lib.optionalAttrs (policy != null) {
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

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          policy =
            if builtins.hasAttr system opencodePolicy.packages
            then opencodePolicy.packages.${system}.opencode-policy
            else null;
        in
        {
          default = pkgs.mkShell {
            packages = [ pkgs.just ] ++ lib.optional (policy != null) policy;
          };
        });
    };
}

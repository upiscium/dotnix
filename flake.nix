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

      packageRegistry = import ./lib/package-registry.nix {
        inherit lib systems;
        packagesDir = ./packages;
        reservedNames = [ "just" ];
      };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          # Bootstrap utility; custom portable applications are discovered
          # automatically from packages/<name>/default.nix.
          just = pkgs.just;
        }
        // packageRegistry.forSystem system pkgs);

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
              profile_args=()
              if [ -n "''${DOTNIX_PROFILE:-}" ]; then
                profile_args=(--profile "$DOTNIX_PROFILE")
              fi

              exec nix profile add "''${profile_args[@]}" "path:${self.outPath}#$package"
            '';
          };
        in
        {
          install = {
            type = "app";
            program = "${installer}/bin/dotnix-install";
          };
        });

      checks =
        assert lib.assertMsg (!(builtins.pathExists ./config.d))
          "root config.d/ is forbidden; move configuration to its semantic owner";
        forAllSystems (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            portablePackages = packageRegistry.forSystem system pkgs;
            packageChecks = lib.mapAttrs'
              (name: package: lib.nameValuePair "${name}-package" package)
              portablePackages;
            policy =
              if builtins.hasAttr system opencodePolicy.packages
              then opencodePolicy.packages.${system}.opencode-policy
              else null;
          in
          packageChecks
          // {
            justfile = pkgs.runCommand "dotnix-justfile-check" {
              nativeBuildInputs = [ pkgs.just ];
            } ''
              just --justfile ${./justfile} --list > "$out"
            '';
          }
          // lib.optionalAttrs (system == "x86_64-linux") {
            package-registry-contract = import ./tests/package-registry {
              inherit lib pkgs;
            };
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

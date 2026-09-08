{
  description = "dotnix portable package distribution, repository policy, and development boundary";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    opencodeContract = {
      url = "github:upiscium/OpencodeContract";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, opencodeContract }:
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
            contract =
              if builtins.hasAttr system opencodeContract.packages
              then opencodeContract.packages.${system}.opencode-contract
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
          // lib.optionalAttrs (contract != null) {
            opencode-contract = pkgs.runCommand "dotnix-opencode-contract" {
              nativeBuildInputs = [ contract ];
            } ''
              opencode-contract audit-consumer \
                --profile global \
                --consumer ${self} \
                --strict
              touch "$out"
            '';
          });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          contract =
            if builtins.hasAttr system opencodeContract.packages
            then opencodeContract.packages.${system}.opencode-contract
            else null;
        in
        {
          default = pkgs.mkShell {
            packages = [ pkgs.just pkgs.python3 ] ++ lib.optional (contract != null) contract;
          };
        });
    };
}

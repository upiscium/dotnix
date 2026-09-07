{ lib }:
let
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
  ];
  pkgs = {
    callPackage = path: args: (import path) args;
  };
  registryFor = caseName:
    import ../../lib/package-registry.nix {
      inherit lib systems;
      packagesDir = ../fixtures/package-registry + "/${caseName}/packages";
      reservedNames = [ "just" ];
    };
in
{
  valid = let
    registry = registryFor "valid";
    selected = registry.forSystem "x86_64-linux" pkgs;
    excluded = registry.forSystem "aarch64-darwin" pkgs;
  in {
    expectSuccess = true;
    expectedMessage = null;
    expression =
      builtins.deepSeq selected
        (registry.names == [ "example" ]
          && selected.example == "example-package"
          && !(builtins.hasAttr "example" excluded));
  };

  invalid-name = {
    expectSuccess = false;
    expectedMessage = "portable package directory names must match";
    expression = (registryFor "invalid-name").names == [ "InvalidName" ];
  };

  reserved-name = {
    expectSuccess = false;
    expectedMessage = "portable package names collide with reserved root packages";
    expression = (registryFor "reserved-name").names == [ "just" ];
  };

  systems-not-list = let
    registry = registryFor "systems-not-list";
  in {
    expectSuccess = false;
    expectedMessage = "systems.nix must evaluate to a list";
    expression = builtins.deepSeq (registry.systemsFor "example") true;
  };

  systems-non-string = let
    registry = registryFor "systems-non-string";
  in {
    expectSuccess = false;
    expectedMessage = "systems.nix must contain only system strings";
    expression = builtins.deepSeq (registry.systemsFor "example") true;
  };

  systems-duplicate = let
    registry = registryFor "systems-duplicate";
  in {
    expectSuccess = false;
    expectedMessage = "systems.nix contains duplicate systems";
    expression = builtins.deepSeq (registry.systemsFor "example") true;
  };

  systems-unsupported = let
    registry = registryFor "systems-unsupported";
  in {
    expectSuccess = false;
    expectedMessage = "systems.nix contains systems outside the root portable contract";
    expression = builtins.deepSeq (registry.systemsFor "example") true;
  };

  default-non-function = let
    registry = registryFor "default-non-function";
  in {
    expectSuccess = false;
    expectedMessage = "default.nix must evaluate to a function suitable for callPackage";
    expression =
      builtins.deepSeq ((registry.forSystem "x86_64-linux" pkgs).example) true;
  };
}

{ lib, pkgs }:
let
  cases = import ./cases.nix { inherit lib; };
  names = lib.sort builtins.lessThan (lib.attrNames cases);
  results = lib.genAttrs names (name:
    let
      case = cases.${name};
    in
    builtins.tryEval (
      assert case.expression;
      true
    ));
  failed = lib.filter
    (name: results.${name}.success != cases.${name}.expectSuccess)
    names;
  aggregate = assert lib.assertMsg (failed == [])
    "package-registry contract cases failed: ${lib.concatStringsSep ", " failed}";
    true;
in
assert aggregate;
pkgs.runCommand "package-registry-contract-tests" { } ''
  touch "$out"
''

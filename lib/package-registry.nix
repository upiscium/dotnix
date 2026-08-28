{ lib, packagesDir, systems, reservedNames ? [ ] }:
let
  entries = builtins.readDir packagesDir;

  names = lib.sort builtins.lessThan (
    lib.attrNames (
      lib.filterAttrs
        (name: type:
          type == "directory"
          && builtins.pathExists (packagesDir + "/${name}/default.nix"))
        entries
    )
  );

  invalidNames = lib.filter
    (name: builtins.match "^[a-z0-9][a-z0-9._-]*$" name == null)
    names;

  reservedCollisions = lib.intersectLists reservedNames names;

  systemsFor = name:
    let
      systemsFile = packagesDir + "/${name}/systems.nix";
      declared =
        if builtins.pathExists systemsFile
        then import systemsFile
        else systems;
      invalidSystems = lib.filter (system: !(lib.elem system systems)) declared;
    in
    assert lib.assertMsg (builtins.isList declared)
      "packages/${name}/systems.nix must evaluate to a list";
    assert lib.assertMsg (lib.all builtins.isString declared)
      "packages/${name}/systems.nix must contain only system strings";
    assert lib.assertMsg (lib.length declared == lib.length (lib.unique declared))
      "packages/${name}/systems.nix contains duplicate systems";
    assert lib.assertMsg (invalidSystems == [ ])
      "packages/${name}/systems.nix contains systems outside the root portable contract: ${lib.concatStringsSep ", " invalidSystems}";
    declared;

  forSystem = system: pkgs:
    let
      selectedNames = lib.filter (name: lib.elem system (systemsFor name)) names;
    in
    lib.genAttrs selectedNames (name:
      let
        packagePath = packagesDir + "/${name}/default.nix";
        packageFunction = import packagePath;
        extraArgs = lib.optionalAttrs
          (builtins.isFunction packageFunction
            && builtins.hasAttr "pkgs" (builtins.functionArgs packageFunction))
          { inherit pkgs; };
      in
      assert lib.assertMsg (builtins.isFunction packageFunction)
        "packages/${name}/default.nix must evaluate to a function suitable for callPackage";
      pkgs.callPackage packagePath extraArgs);
in
assert lib.assertMsg (invalidNames == [ ])
  "portable package directory names must match ^[a-z0-9][a-z0-9._-]*$: ${lib.concatStringsSep ", " invalidNames}";
assert lib.assertMsg (reservedCollisions == [ ])
  "portable package names collide with reserved root packages: ${lib.concatStringsSep ", " reservedCollisions}";
{
  inherit names systemsFor forSystem;
}

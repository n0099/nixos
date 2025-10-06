{ lib, ... }:

{
  age.secrets = # https://github.com/ryantm/agenix/pull/348
    lib.genAttrs (lib.map (lib.removeSuffix ".age") (lib.attrNames (import ./secrets.nix))) (name: {
      file = ./${name}.age;
    });
}

{ lib, ... }:

{
  age.secrets = # https://github.com/ryantm/agenix/pull/348
    (name: {
      file = ./${name}.age;
    })
    |> lib.genAttrs (import ./secrets.nix |> lib.attrNames |> lib.map (lib.removeSuffix ".age"));
}

{
  flake.modules.nixos.secrets =
    { lib, ... }:

    {
      age.secrets = # https://github.com/ryantm/agenix/pull/348
        (name: { file = ./${name}.age; })
        |> lib.genAttrs (import ../secrets/secrets.nix |> lib.attrNames |> map (lib.removeSuffix ".age"));
    };
}

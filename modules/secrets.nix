{ lib, inputs, ... }:

{
  flake.modules.nixos = {
    agenix = with inputs.agenix; {
      imports = [ nixosModules.default ];
      config.environment.systemPackages = [ packages."x86_64-linux".default ];
    };
    secrets.config.age.secrets = # https://github.com/ryantm/agenix/pull/348
      (name: { file = ./${name}.age; })
      |> lib.genAttrs (import ../secrets/secrets.nix |> lib.attrNames |> map (lib.removeSuffix ".age"));
  };
}

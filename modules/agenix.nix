{ inputs, ... }:

{
  flake.modules.nixos.agenix = with inputs.agenix; {
    imports = [ nixosModules.default ];
    config.environment.systemPackages = [ packages."x86_64-linux".default ];
  };
}

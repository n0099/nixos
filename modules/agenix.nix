{ inputs, ... }:

{
  flake-file.inputs.agenix = {
    url = "github:ryantm/agenix";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      home-manager.follows = "home-manager";
    };
  };
  flake.modules.nixos.agenix = with inputs.agenix; {
    imports = [ nixosModules.default ];
    config.environment.systemPackages = [ packages."x86_64-linux".default ];
  };
}

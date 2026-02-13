{
  inputs = {
    self.submodules = true; # https://github.com/NixOS/nix/pull/12421
    base.url = "./base";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "base/nixpkgs"; # https://discourse.nixos.org/t/flake-how-make-nixpkgs-self-follow-another-inputs-nixpkgs/10867
    };
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs = {
        nixpkgs.follows = "base/nixpkgs";
        home-manager.follows = "base/home-manager";
      };
    };
    minegrub-world-sel-theme = {
      url = "github:Lxtharia/minegrub-world-sel-theme";
      inputs.nixpkgs.follows = "base/nixpkgs";
    };
  };
  outputs =
    { base, ... }@inputs:

    with { inherit (base.inputs) flake-parts import-tree; };
    flake-parts.lib.mkFlake { inputs = base.inputs // inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        flake-parts.flakeModules.modules
        (import-tree [
          ./base/modules
          ./modules
        ])
      ]
      ++ [
        {
          flake.modules.nixos = {
            secrets.imports = [
              ./base/secrets
              ./secrets
            ];
            configuration.imports = [ ./configuration.nix ];
          };
        }
      ];
    };
}

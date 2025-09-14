{
  inputs = {
    base.url = "./base";
    nur = {
      url = "github:nix-community/NUR";
      # https://discourse.nixos.org/t/flake-how-make-nixpkgs-self-follow-another-inputs-nixpkgs/10867
      inputs.nixpkgs.follows = "base/nixpkgs";
    };
  };
  outputs =
    {
      base,
      nur,
      ...
    }@inputs:
    (base.outputs.withModules ({ inherit nur; } // inputs) {
      nixos = [
        nur.modules.nixos.default # https://nur.nix-community.org/documentation/#using-the-flake-in-nixos
        ./configuration.nix
        ./desktop.nix
        ./zfs.nix
      ];
    });
}

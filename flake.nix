{
  nixConfig = {
    extra-substituters = [
      # https://discourse.nixos.org/t/enable-different-priority-substituters-with-flake/56073/7
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store/"
      "https://cache.nixos.org"
      # https://nix-community.org/cache/
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
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
      home-manager = [ ./home/n0099.nix ];
    });
}

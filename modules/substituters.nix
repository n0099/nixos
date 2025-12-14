{ lib, ... }:

{
  flake.modules.nixos.substituters = lib.mkMerge [
    {
      nix.settings = {
        # https://nix-community.org/cache/
        substituters = [ "https://nix-community.cachix.org" ];
        trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
      };
    }
    {
      nix.settings.substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ]; # https://mirrors.tuna.tsinghua.edu.cn/help/nix-channels/
    }
  ];
}

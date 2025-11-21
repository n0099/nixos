{ ... }:

{
  # https://wiki.gentoo.org/wiki/LTO
  # https://old.reddit.com/r/NixOS/comments/146wdfk/lto_by_default/
  # https://old.reddit.com/r/NixOS/comments/yww3mr/lto_and_pgo_in_nixos/
  # https://github.com/ZaMaZaN4iK/awesome-pgo
  # https://github.com/NixOS/nixpkgs/issues/306953
  # https://github.com/NixOS/nixpkgs/pull/393458
  nixpkgs.config.replaceStdenv = { pkgs }: pkgs.stdenvAdapters.overrideCC pkgs.fastStdenv pkgs.gcc; # https://github.com/NixOS/nixpkgs/pull/207419
}

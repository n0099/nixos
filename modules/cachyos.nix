{
  flake-file.inputs.nix-cachyos-kernel = {
    # https://discourse.nixos.org/t/chaotic-nyx-is-archved-what-are-some-alternatives/73073
    url = "github:xddxdd/nix-cachyos-kernel";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake.modules.nixos.cachyos =
    {
      config,
      pkgs,
      lib,
      inputs,
      ...
    }:

    let
      cfg = config.n0099.cachyos;
    in
    {
      options.n0099.cachyos = {
        enable = lib.mkEnableOption "";
        variant = lib.mkOption { type = lib.types.str; }; # https://wiki.cachyos.org/features/kernel/#variants
        baseKernel = lib.mkOption {
          type = lib.types.package;
          default =
            let
              # https://github.com/CachyOS/kernel-patches/issues/140
              # https://github.com/xddxdd/nix-cachyos-kernel/commit/a3da9122076ae33d52828d1e6c4a2595378f0ca2#diff-352bbe444aff13cc4c129bd885cbbb136eb0aa2db3bacfe3586909d7d337e4c2R16
              lts = (lib.importJSON "${inputs.nix-cachyos-kernel}/kernel-cachyos/version.json").lts;
            in
            rec {
              inherit (src) outPath; # to pass `isStorePath` check of https://github.com/NixOS/nixpkgs/blob/e2fbb67cc1eedacce97b850cd5664d23e15eb984/lib/types.nix#L647
              inherit (lts) version;
              src = pkgs.fetchurl {
                inherit (lts) url hash;
              };
            };
        };
      };
      config = lib.mkIf cfg.enable {
        boot.kernelPackages =
          {
            autofdo = true; # https://cachyos.org/blog/2411-kernel-autofdo/
            lto = "full"; # https://www.kernelconfig.io/config_lto_clang_full
            stdenv = pkgs.clangStdenv; # using our stdenv with possibly configured `hostPlatform.gcc.march`
            inherit (cfg.baseKernel) version src; # https://github.com/xddxdd/nix-cachyos-kernel/blob/dc3941ceb1cc0b303ddefc5e5fa1577a2d7856d7/kernel-cachyos/default.nix#L16
          }
          |> inputs.nix-cachyos-kernel.outputs.packages.${pkgs.stdenv.system}."linux-cachyos-${cfg.variant}".override # https://github.com/xddxdd/nix-cachyos-kernel/issues/23#issuecomment-3764296449
          |> pkgs.linuxKernel.packagesFor;
      };
    };
}

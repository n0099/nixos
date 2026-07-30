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
          type = with lib.types; either package str;
          default = "lts";
          apply =
            value:
            if lib.isString value then
              let
                # https://github.com/CachyOS/kernel-patches/issues/140
                # https://github.com/xddxdd/nix-cachyos-kernel/commit/12eb1a90ebec95e37c81cb0f9b2a0907ffd6704f#diff-9fd890849d1d04eb0bc88266a8df0ca8404613f123ab5a5e5a1112e073b7145cR44
                prepatched =
                  (lib.importJSON "${inputs.nix-cachyos-kernel}/kernel-cachyos/version.json")
                  ."linux-cachyos-${value}";
              in
              rec {
                inherit (src) outPath; # to pass `isStorePath` check of https://github.com/NixOS/nixpkgs/blob/e2fbb67cc1eedacce97b850cd5664d23e15eb984/lib/types.nix#L647
                inherit (prepatched) version;
                src = pkgs.fetchurl {
                  inherit (prepatched) url hash;
                };
              }
            else
              value;
        };
        mkCachyKernelOverrides = lib.mkOption { type = with lib.types; attrsOf anything; };
      };
      config = lib.mkIf cfg.enable (
        let
          extraMakeFlags =
            let
              platform = config.nixpkgs.hostPlatform.gcc;
            in
            lib.concatMap # https://github.com/NixOS/nixpkgs/pull/431961#issuecomment-5035234990
              (
                key:
                lib.optional (platform ? arch) "${key}+=-march=${platform.arch}"
                ++ lib.optional (platform ? tune) "${key}+=-mtune=${platform.tune}"
              )
              [
                "KCFLAGS"
                "KCPPFLAGS"
              ];
        in
        {
          boot = {
            kernelPackages = (
              {
                autofdo = true; # https://cachyos.org/blog/2411-kernel-autofdo/
                lto = "full"; # https://www.kernelconfig.io/config_lto_clang_full
                stdenv = pkgs.clangStdenv; # using our stdenv that may built with configured `hostPlatform.gcc.{arch,tune}` so don't have to build nix-cachyos-kernel's stdenv again
                bbr3 = true; # https://www.phoronix.com/news/Google-BBRv3-Linux
                inherit (cfg.baseKernel) version src; # https://github.com/xddxdd/nix-cachyos-kernel/blob/dc3941ceb1cc0b303ddefc5e5fa1577a2d7856d7/kernel-cachyos/default.nix#L16
                inherit extraMakeFlags;
              }
              // cfg.mkCachyKernelOverrides
              |> inputs.nix-cachyos-kernel.outputs.packages.${pkgs.stdenv.system}."linux-cachyos-${cfg.variant}".override # https://github.com/xddxdd/nix-cachyos-kernel/issues/23#issuecomment-3764296449
              |> pkgs.linuxKernel.packagesFor
            );
            zfs.modulePackage = # https://github.com/NixOS/nixpkgs/issues/473637#issuecomment-5037550911
              config.boot.kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.overrideAttrs # https://github.com/NixOS/nixpkgs/blob/fd1462031fdee08f65fd0b4c6b64e22239a77870/nixos/modules/tasks/filesystems/zfs.nix#L22
                (prev: {
                  configureFlags = lib.filter (i: !(lib.hasInfix "+=" i)) prev.configureFlags;
                })
              |> lib.mkIf (extraMakeFlags != [ ]);
          };
        }
      );
    };
}

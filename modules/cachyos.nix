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
      getVariant =
        variant:
        inputs.nix-cachyos-kernel.outputs.packages.${pkgs.stdenv.system}."linux-cachyos-${variant}";
    in
    {
      options.n0099.cachyos = {
        enable = lib.mkEnableOption "";
        variant = lib.mkOption { type = lib.types.str; }; # https://wiki.cachyos.org/features/kernel/#variants
        baseKernel = lib.mkOption {
          type = lib.types.str;
          default = cfg.variant;
          apply =
            value:
            let
              variant = getVariant value;
            in
            {
              inherit (variant) version cachyosConfigFile;
              src = pkgs.fetchurl {
                inherit (variant.src.src) url hash;
              };
              cachyosPatchesSrc =
                let
                  # https://github.com/xddxdd/nix-cachyos-kernel/blob/9d1001801db6023d5ce07707fea6af75de260d3f/kernel-cachyos/mkCachyKernel.nix#L220 didn't passthru its original `cachyosPatchesSrc`
                  variantJSON =
                    ("${inputs.nix-cachyos-kernel}/kernel-cachyos/version.json" |> lib.readFile |> lib.fromJSON)
                    ."linux-cachyos-${builtins.match "^([^-]+).*" value |> lib.head}";
                in
                pkgs.fetchFromGitHub {
                  # https://github.com/xddxdd/nix-cachyos-kernel/blob/b1332396df6e880d7e3b6b451c6a74132ce8cf66/kernel-cachyos/default.nix#L27
                  owner = "CachyOS";
                  repo = "kernel-patches";
                  rev = variantJSON.patchRev;
                  rootDir = "${variantJSON.patchVersion}/";
                  hash = variantJSON.patchHash;
                };
            };
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
          boot.kernelPackages = (
            {
              stdenv = pkgs.clangStdenv; # using our stdenv that may built with configured `hostPlatform.gcc.{arch,tune}` so don't have to build nix-cachyos-kernel's stdenv again
              bbr3 = true; # https://www.phoronix.com/news/Google-BBRv3-Linux
              inherit extraMakeFlags;
              inherit (cfg.baseKernel) version src; # https://github.com/xddxdd/nix-cachyos-kernel/blob/dc3941ceb1cc0b303ddefc5e5fa1577a2d7856d7/kernel-cachyos/default.nix#L16
            }
            // lib.optionalAttrs (cfg.baseKernel ? cachyosConfigFile) {
              inherit (cfg.baseKernel) cachyosConfigFile;
            }
            // lib.optionalAttrs (cfg.baseKernel ? cachyosPatchesSrc) {
              inherit (cfg.baseKernel) cachyosPatchesSrc;
            }
            // lib.optionalAttrs (lib.hasSuffix "-lto" cfg.variant) {
              autofdo = true; # https://cachyos.org/blog/2411-kernel-autofdo/
              lto = "full"; # https://www.kernelconfig.io/config_lto_clang_full
            }
            // cfg.mkCachyKernelOverrides
            |> (getVariant cfg.variant).override # https://github.com/xddxdd/nix-cachyos-kernel/issues/23#issuecomment-3764296449
            |> pkgs.linuxKernel.packagesFor
          );
          nixpkgs.overlays =
            [
              (_: prev: {
                kernelPackagesExtensions = prev.kernelPackagesExtensions ++ [
                  # https://github.com/NixOS/nixpkgs/blob/5dfba6236110080a54247d6460bc2ff5dda939cc/pkgs/top-level/linux-kernels.nix#L668
                  (
                    _: prev:
                    let
                      pkgName = config.boot.zfs.package.kernelModuleAttribute; # https://github.com/NixOS/nixpkgs/blob/fd1462031fdee08f65fd0b4c6b64e22239a77870/nixos/modules/tasks/filesystems/zfs.nix#L22
                    in
                    {
                      ${pkgName} = prev.${pkgName}.overrideAttrs (prev: {
                        # https://github.com/NixOS/nixpkgs/issues/473637#issuecomment-5498332999
                        configureFlags = lib.filter (i: !(lib.hasInfix "+=" i)) prev.configureFlags;
                      });
                    }
                  )
                ];
              })
            ]
            |> lib.mkIf (extraMakeFlags != [ ]);
        }
      );
    };
}

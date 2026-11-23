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
        mkCachyKernelOverrides = lib.mkOption { type = with lib.types; attrsOf anything; };
        useLTSWhenVariantBrokeZfs = lib.mkEnableOption "" // {
          default = config.boot.zfs.enabled;
        };
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
          mkKernelPackages =
            variant:
            {
              stdenv = pkgs.clangStdenv; # using our stdenv that may built with configured `hostPlatform.gcc.{arch,tune}` so don't have to build nix-cachyos-kernel's stdenv again
              bbr3 = true; # https://www.phoronix.com/news/Google-BBRv3-Linux
              inherit extraMakeFlags;
            }
            // lib.optionalAttrs (lib.hasSuffix "-lto" variant) {
              autofdo = true; # https://cachyos.org/blog/2411-kernel-autofdo/
              lto = "full"; # https://www.kernelconfig.io/config_lto_clang_full
            }
            // cfg.mkCachyKernelOverrides
            |> (getVariant variant).override # https://github.com/xddxdd/nix-cachyos-kernel/issues/23#issuecomment-3764296449
            |> pkgs.linuxKernel.packagesFor;
          zfsPackageName = config.boot.zfs.package.kernelModuleAttribute; # https://github.com/NixOS/nixpkgs/blob/fd1462031fdee08f65fd0b4c6b64e22239a77870/nixos/modules/tasks/filesystems/zfs.nix#L22
          variant =
            if
              cfg.useLTSWhenVariantBrokeZfs && (mkKernelPackages cfg.variant).${zfsPackageName}.meta.broken # https://github.com/NixOS/nixpkgs/pull/341596#issuecomment-2367200551
            then
              if lib.hasInfix "-lto" cfg.variant then "lts-lto" else "lts"
            else
              cfg.variant;
        in
        {
          boot.kernelPackages = mkKernelPackages variant;
          nixpkgs.overlays =
            [
              (_: prev: {
                kernelPackagesExtensions = prev.kernelPackagesExtensions ++ [
                  # https://github.com/NixOS/nixpkgs/blob/5dfba6236110080a54247d6460bc2ff5dda939cc/pkgs/top-level/linux-kernels.nix#L668
                  (
                    _: prev:
                    let
                    in
                    {
                      ${zfsPackageName} = prev.${zfsPackageName}.overrideAttrs (prev: {
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

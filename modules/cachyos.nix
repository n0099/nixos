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
          default = pkgs.linux_latest; # https://github.com/xddxdd/nix-cachyos-kernel/blob/dc3941ceb1cc0b303ddefc5e5fa1577a2d7856d7/kernel-cachyos/default.nix#L16
        };
      };
      config = {
        nixpkgs.overlays = [ inputs.nix-cachyos-kernel.outputs.overlay ]; # https://github.com/xddxdd/nix-cachyos-kernel/blob/dc3941ceb1cc0b303ddefc5e5fa1577a2d7856d7/flake.nix#L95
        boot.kernelPackages = pkgs.cachyosKernels."linuxPackages-cachyos-${cfg.variant}".extend (
          final: prev: {
            kernel = prev.kernel.override {
              inherit (cfg.baseKernel) version src;
              structuredExtraConfig =
                with lib.kernel;
                lib.optionalAttrs (lib.hasSuffix "-lto" cfg.variant) {
                  LTO_CLANG_FULL = yes; # https://www.kernelconfig.io/config_lto_clang_full
                  LTO_CLANG_THIN = no; # https://github.com/xddxdd/nix-cachyos-kernel/blob/52d03c7f4e6f78cbf9e1ec1d78101b2369ff8f7c/kernel-cachyos/mkCachyKernel.nix#L108-L111
                };
            };
          }
        );
      };
    };
}

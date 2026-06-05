{
  flake.modules.nixos.march =
    { config, lib, ... }:

    {
      options.n0099.march = {
        enable = lib.mkEnableOption "";
        arch = lib.mkOption { type = lib.types.str; }; # https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html#index-march-14
      };
      config =
        with { inherit (config.n0099.march) enable arch; };
        lib.mkMerge [
          {
            # https://wiki.nixos.org/wiki/Build_flags#Building_the_whole_system_on_NixOS
            # https://discourse.nixos.org/t/pre-rfc-gradual-transition-of-nixos-x86-64-baseline-to-x86-64-v3-with-an-intermediate-step-to-x86-64-v2/35924
            # https://wiki.gentoo.org/wiki/GCC_optimization#-march
            # https://news.ycombinator.com/item?id=45758392
            # https://wiki.debian.org/ArchitectureVariants
            nixpkgs.hostPlatform = {
              gcc = {
                inherit arch;
                tune = arch;
              };
              system = "x86_64-linux";
            };
            nix.settings.system-features = [ "gccarch-${arch}" ];
          }
          {
            nix.settings.keep-outputs = true; # https://discourse.nixos.org/t/rebuild-nixos-offline/3679/16
          }
        ]
        |> lib.mkIf enable;
    };
}

{
  flake.modules.nixos.optimize =
    { config, lib, ... }:

    let
      cfg = config.n0099.optimize;
    in
    {
      options.n0099.optimize = {
        arch = lib.mkOption {
          # https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html#index-march-14
          type = with lib.types; nullOr str;
          default = null;
        };
      };
      config =
        lib.mkMerge [
          {
            # https://wiki.nixos.org/wiki/Build_flags#Building_the_whole_system_on_NixOS
            # https://discourse.nixos.org/t/pre-rfc-gradual-transition-of-nixos-x86-64-baseline-to-x86-64-v3-with-an-intermediate-step-to-x86-64-v2/35924
            # https://wiki.gentoo.org/wiki/GCC_optimization#-march
            # https://news.ycombinator.com/item?id=45758392
            # https://wiki.debian.org/ArchitectureVariants
            nixpkgs.hostPlatform = {
              gcc = {
                inherit (cfg) arch;
                tune = cfg.arch;
              };
              system = "x86_64-linux";
            };
            nix.settings.system-features = [ "gccarch-${cfg.arch}" ];
          }
          {
            nix.settings.keep-outputs = true; # https://discourse.nixos.org/t/rebuild-nixos-offline/3679/16
          }
        ]
        |> lib.mkIf (cfg.arch != null);
    };
}

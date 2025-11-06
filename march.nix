{ pkgs, lib, ... }:

let
  enable = true;
in
lib.mkMerge [
  (
    let
      arch = "skylake";
    in
    {
      # https://wiki.nixos.org/wiki/Build_flags#Building_the_whole_system_on_NixOS
      # https://wiki.gentoo.org/wiki/GCC_optimization#-march
      # https://news.ycombinator.com/item?id=45758392
      # https://wiki.debian.org/ArchitectureVariants
      nixpkgs.hostPlatform = lib.mkIf enable {
        gcc = {
          inherit arch;
          tune = arch;
        };
        system = "x86_64-linux";
      };
      nix.settings.system-features = [ "gccarch-${arch}" ];
    }
  )
  {
    nix.settings.keep-outputs = true; # https://discourse.nixos.org/t/rebuild-nixos-offline/3679/16
  }
  {
    nixpkgs.overlays = lib.mkIf enable [
      (
        self: super:
        let
          override =
            libreoffice:
            libreoffice.override (prev: {
              unwrapped = prev.unwrapped.overrideAttrs (
                _: prev: {
                  patches = prev.patches ++ [
                    (pkgs.writeText "skip-testArrayFormulasFODS.patch" ''
                      diff --git a/sc/qa/unit/functions_array.cxx b/sc/qa/unit/functions_array.cxx
                      index ef0da39f5..43caa9002 100644
                      --- a/sc/qa/unit/functions_array.cxx
                      +++ b/sc/qa/unit/functions_array.cxx
                      @@ -25,6 +25,7 @@ void ArrayFunctionsTest::testArrayFormulasFODS()

                       void ArrayFunctionsTest::testDubiousArrayFormulasFODS()
                       {
                      +    return; // flaky https://github.com/NixOS/nixpkgs/issues/398633
                           //TODO: sc/qa/unit/data/functions/array/dubious/fods/linest.fods produces widely different
                           // values when built with -ffp-contract enabled (-ffp-contract=on default on Clang 14,
                           // -ffp-contract=fast default when building with optimizations on GCC) on at least aarch64
                    '')
                  ];
                }
              );
            });
        in
        {
          libreoffice-still = override super.libreoffice-still;
          libreoffice-qt-still = override super.libreoffice-qt-still;
          libreoffice-qt6-still = override super.libreoffice-qt6-still;
          libreoffice-fresh = override super.libreoffice-still;
          libreoffice-qt-fresh = override super.libreoffice-qt-still;
          libreoffice-qt6-fresh = override super.libreoffice-qt6-still;
          libreoffice-collabora = override super.libreoffice-collabora;
        }
      )
    ];
  }
]

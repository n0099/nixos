{
  flake.modules.nixos.march =
    { pkgs, lib, ... }:

    lib.mkMerge [
      {
        n0099.march = {
          enable = true;
          arch = "skylake";
        };
      }
      {
        # https://stackoverflow.com/questions/69971612/how-does-march-native-affect-floating-point-accuracy
        nixpkgs.overlays = [
          (
            final: prev:
            let
              override =
                libreoffice:
                libreoffice.override (prev: {
                  unwrapped = prev.unwrapped.overrideAttrs (prev: {
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
                  });
                });
            in
            {
              libreoffice-still = override prev.libreoffice-still;
              libreoffice-qt-still = override prev.libreoffice-qt-still;
              libreoffice-fresh = override prev.libreoffice-still;
              libreoffice-qt-fresh = override prev.libreoffice-qt-still;
              libreoffice-collabora = override prev.libreoffice-collabora;
            }
          )
          (final: prev: {
            assimp = prev.assimp.overrideAttrs { doCheck = false; }; # https://github.com/assimp/assimp/issues/6342
          })
          (
            final: prev:
            let
              overrideAttrs =
                ffmpeg:
                ffmpeg.overrideAttrs (prev: {
                  postPatch = (prev.postPatch or "") + ''
                    # https://github.com/NixOS/nixpkgs/issues/398625
                    sed -i '/fate-vsynth%-huffyuvbgra/d' tests/fate/vcodec.mak
                    sed -i 's/huffyuvbgra//' tests/fate/vcodec.mak
                  '';
                });
            in
            {
              ffmpeg = overrideAttrs prev.ffmpeg;
              ffmpeg-full = overrideAttrs prev.ffmpeg;
              ffmpeg-headless = overrideAttrs prev.ffmpeg-headless;
              ffmpeg_8 = overrideAttrs prev.ffmpeg;
              ffmpeg_8-full = overrideAttrs prev.ffmpeg;
              ffmpeg_8-headless = overrideAttrs prev.ffmpeg-headless;
            }
          )
        ];
      }
    ];
}

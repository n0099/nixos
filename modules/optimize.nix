{
  flake.modules.nixos.optimize =
    { lib, ... }:

    lib.mkMerge [
      {
        n0099.optimize = {
          stdenv = true;
          python = true;
        };
      }
      {
        n0099.optimize.arch = "skylake";
        nixpkgs.overlays = [
          # https://stackoverflow.com/questions/69971612/how-does-march-native-affect-floating-point-accuracy
          (_: prev: {
            assimp = prev.assimp.overrideAttrs { doCheck = false; }; # https://github.com/assimp/assimp/issues/6342
          })
        ];
      }
    ];
}

{
  flake.modules.nixos.march =
    { lib, ... }:

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
          (final: prev: {
            assimp = prev.assimp.overrideAttrs { doCheck = false; }; # https://github.com/assimp/assimp/issues/6342
          })
        ];
      }
    ];
}

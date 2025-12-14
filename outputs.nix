{ flake-parts, import-tree, ... }@inputs:

flake-parts.lib.mkFlake { inherit inputs; } {
  systems = [ "x86_64-linux" ];
  imports = [
    ./inputs.nix
  ]
  ++ [
    flake-parts.flakeModules.modules
    (import-tree ./modules)
  ];
}

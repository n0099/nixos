{ flake-parts, import-tree, ... }@inputs:

flake-parts.lib.mkFlake { inherit inputs; } {
  systems = [ "x86_64-linux" ];
  imports = [
    flake-parts.flakeModules.modules
    ./inputs.nix
    (import-tree ./modules)
  ];
}

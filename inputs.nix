{
  flake-file.inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.zst";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-file.url = "github:denful/flake-file";
    import-tree.url = "github:denful/import-tree";
  };
}

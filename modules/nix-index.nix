{
  flake-file.inputs.nix-index-database = {
    url = "github:nix-community/nix-index-database";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake.modules.nixos.nix-index = { inputs, ... }: {
    imports = [
      inputs.nix-index-database.nixosModules.default
      {
        programs = {
          # https://github.com/nix-community/nix-index-database/blob/f8ed6cdcb1fd28a6ab7b61f4467a4f67fe2d9074/nixos-module.nix#L23
          # prefer faster nixos module `programs.command-not-found`: https://github.com/NixOS/nixpkgs/issues/39789#issuecomment-1000276113
          command-not-found.enable = true;
          nix-index = {
            # https://github.com/NixOS/nixpkgs/blob/4c7870105e7f1fdf9c48688c8d7efc21abf0688a/nixos/modules/programs/nix-index.nix#L47
            enableBashIntegration = false;
            enableFishIntegration = false;
            enableZshIntegration = false;
          };
          nix-index-database.comma.enable = true;
        };
      }
    ];
  };
}

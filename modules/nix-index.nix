{
  flake-file.inputs.nix-index-database = {
    url = "github:nix-community/nix-index-database";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake.modules.homeManager.nix-index = { inputs, ... }: {
    imports = [
      inputs.nix-index-database.homeModules.default
      {
        programs.nix-index = {
          # https://github.com/nix-community/home-manager/blob/cda90fd8838825c689fde9d3f3b4e937937790df/modules/programs/nix-index.nix#L21
          # prefer faster nixos module `programs.command-not-found`: https://github.com/NixOS/nixpkgs/issues/39789#issuecomment-1000276113
          enableBashIntegration = false;
          enableFishIntegration = false;
          enableZshIntegration = false;
          enableNushellIntegration = false;
        };
      }
    ];
  };
}

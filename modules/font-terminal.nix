{
  flake.modules = {
    nixos.font-terminal =
      { pkgs, ... }:

      {
        fonts.packages = with pkgs; [ nerd-fonts.fira-code ];
      };
    homeManager.font-terminal.programs.konsole.profiles.default.font = {
      name = "FiraCode Nerd Font Ret";
      size = 11;
    };
  };
}

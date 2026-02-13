let
  fontFamily = "FiraCode Nerd Font Ret";
in
{
  flake.modules = {
    nixos.font-terminal =
      { pkgs, ... }:

      {
        fonts = {
          packages = with pkgs; [ nerd-fonts.fira-code ];
          fontconfig.defaultFonts.monospace = [ fontFamily ];
        };
      };
    homeManager.font-terminal.programs.konsole.profiles.default.font = {
      name = fontFamily; # Konsole trying to use the `Hack` font by default: https://lists.fedorahosted.org/archives/list/kde@lists.fedoraproject.org/thread/NUW3L6VODVB3EERMQHCMRSLAKUYUW2S5/
      size = 11;
    };
  };
}

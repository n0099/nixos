{
  flake.modules = {
    nixos.git.programs.git.enable = true;
    homeManager.git.programs = {
      git = {
        enable = true;
        settings = {
          user = {
            name = "n0099";
            email = "git@n0099.com";
          };
          push.autoSetupRemote = true;
        };
      };
      difftastic = {
        enable = true;
        git = {
          enable = true;
          diffToolMode = true;
        };
      };
    };
  };
}

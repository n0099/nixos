{ inputs, ... }:

{
  imports = [ inputs.nixvim.nixosModules.nixvim ];
  programs.nixvim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
    plugins = {
      # leap.enable = true;
      trim.enable = true;
      lastplace.enable = true;
    };
    files = {
      # https://github.com/nix-community/nixvim/issues/2418#issuecomment-2413714276i
      "after/ftplugin/nix.lua" = {
        localOpts = { # https://github.com/nix-community/nixvim/pull/3535#discussion_r2191072494
          tabstop = 2;
          shiftwidth = 2;
        };
      };
    };
    opts = {
      # https://superuser.com/questions/505937/how-to-set-tab-to-4-spaces-in-vim/505948#505948
      # https://vi.stackexchange.com/questions/4141/how-to-indent-as-spaces-instead-of-tab
      tabstop = 4;
      shiftwidth = 4;
      expandtab = true;
    };
  };
}

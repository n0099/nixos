{
  flake.modules.homeManager.n0099 =
    { lib, pkgs, ... }:

    lib.mkMerge [
      {
        home.packages = with pkgs; [
          lnav
          ncdu
          file
          tree
          lsof
          nixfmt-tree
          comma
        ];
      }
      {
        programs = {
          atuin = {
            enable = true;
            flags = [ "--disable-up-arrow" ];
            settings = {
              search_mode = "fulltext";
              filter_mode = "directory";
              enter_accept = false;
            };
          };
          tmux = {
            enable = true;
            mouse = true;
            clock24 = true;
            keyMode = "vi";
            terminal = "tmux";
            extraConfig = ''
              # https://stackoverflow.com/questions/41783367/tmux-tmux-true-color-is-not-working-properly/78084843#78084843
              set -as terminal-features ",putty*:RGB"
            '';
          };
        };
      }
      {
        programs.nh.enable = true;
        home.packages = with pkgs; [
          nvd
          # dix # https://github.com/NixOS/nixpkgs/pull/409440
          nix-output-monitor
        ];
      }
    ];
}

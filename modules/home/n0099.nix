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
            package = pkgs.atuin.overrideAttrs (prev: {
              patches = prev.patches ++ [
                (pkgs.fetchpatch2 {
                  url = "https://github.com/atuinsh/atuin/pull/2903.patch";
                  hash = "sha256-mBS7XzUSDK/Rxm1AeAYXnP2AflG8Ldp4+yaG6riWJ28=";
                })
              ];
            });
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
          dix
          nix-output-monitor
        ];
      }
    ];
}

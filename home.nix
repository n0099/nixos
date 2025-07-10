{ config, pkgs, ... }:

{
  home = {
    stateVersion = "25.05";
    shellAliases = {
      sudo = "sudo "; # https://askubuntu.com/questions/22037/aliases-not-available-when-using-sudo/22043#22043
    };
  };
  services.ssh-agent.enable = true;
  programs = {
    zsh = {
      enable = true;
      antidote = {
        enable = true;
        plugins =
          [ "getantidote/use-omz" ]
          ++ map (i: "ohmyzsh/ohmyzsh " + i)
            ([ "path:lib" "path:themes/duellj.zsh-theme" ]
            ++ map
              (i: "path:plugins/" + i)
              [ "git" "command-not-found" "colorize" "colored-man-pages" "zsh-interactive-cd" ])
          ++ [ "zdharma-continuum/fast-syntax-highlighting" "zsh-users/zsh-autosuggestions" ]
        ;
      };
    };
    git = {
      userName = "n0099";
      userEmail = "n@n0099.net";
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
    htop.enable = true;
  };
}

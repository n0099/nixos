{ pkgs, ... }:

{
  imports = [ ./zsh.nix ];
  home = {
    stateVersion = "25.05";
    shellAliases = {
      sudo = "sudo "; # https://askubuntu.com/questions/22037/aliases-not-available-when-using-sudo/22043#22043
    };
    packages = with pkgs; [
      certbot
      lnav
      parallel
      nixfmt-tree
    ];
  };
  services.ssh-agent.enable = true;
  programs = {
    atuin = {
      enable = true;
      enableZshIntegration = true;
      flags = [ "--disable-up-arrow" ];
      settings = {
        search_mode = "fulltext";
        filter_mode = "directory";
        enter_accept = false;
      };
    };
    git = {
      enable = true;
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

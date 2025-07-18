{ lib, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    history = {
      size = 100000;
      share = false;
    };
    sessionVariables = { # https://unix.stackexchange.com/questions/743817/how-to-start-tmux-in-a-way-that-it-inherits-all-environment-variables-from-the-c
      COLORTERM = "truecolor"; # https://github.com/termstandard/colors
      LESS = "--mouse -R";
    };
    antidote = {
      enable = true;
      plugins =
        [ "getantidote/use-omz" ]
        ++ map
          (i: "ohmyzsh/ohmyzsh " + i)
          ([ "path:lib" "path:themes/fino-time.zsh-theme" ]
          ++ map
            (i: "path:plugins/" + i)
            [ "alias-finder" "common-aliases" "colored-man-pages" "extract" "docker" "docker-compose" "last-working-dir" "git" "isodate" "safe-paste" "sudo" "systemd" ])
        ++ [ "zdharma-continuum/fast-syntax-highlighting" "zsh-users/zsh-autosuggestions" "nix-community/nix-zsh-completions" ];
    };
    # https://github.com/nix-community/home-manager/blob/9b0873b46c9f9e4b7aa01eb634952c206af53068/modules/programs/zsh.nix#L803-L806
    # not using `oh-my-zsh.extraConfig` due to its requires enable oh-my-zsh and it's managed by antidote
    initContent = lib.mkOrder 800 (lib.readFile ./.zshrc);
  };
}

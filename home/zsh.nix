{ lib, pkgs, ... }:

let
  omzPrefix = suffixs: map (i: "ohmyzsh/ohmyzsh " + i) suffixs;
  omzPluginPrefix = plugins: omzPrefix (map (i: "path:plugins/" + i) plugins);
in
lib.mkMerge
[{
  programs.zsh = {
    enable = true;
    sessionVariables = { # https://unix.stackexchange.com/questions/743817/how-to-start-tmux-in-a-way-that-it-inherits-all-environment-variables-from-the-c
      COLORTERM = "truecolor"; # https://github.com/termstandard/colors
      LESS = "--mouse -R";
    };
    history = {
      size = 100000;
      share = false;
    };
    # https://github.com/nix-community/home-manager/blob/9b0873b46c9f9e4b7aa01eb634952c206af53068/modules/programs/zsh.nix#L803-L806
    # not using `oh-my-zsh.extraConfig` due to its requires enable oh-my-zsh and it's managed by antidote
    initContent = lib.mkOrder 800 ''
      # https://superuser.com/questions/410965/command-history-in-zsh
      setopt INC_APPEND_HISTORY
    '';
    antidote = {
      enable = true;
      plugins =
        [ "getantidote/use-omz" ]
        ++ omzPrefix [ "path:lib" "path:themes/fino-time.zsh-theme" ]
        ++ omzPluginPrefix [ "common-aliases" "colored-man-pages" "extract" "docker-compose" "last-working-dir" "git" "isodate" "safe-paste" "sudo" "systemd" ]
        ++ [ "zdharma-continuum/fast-syntax-highlighting" "nix-community/nix-zsh-completions" ];
    };
  };
} {
  home.packages = [ pkgs.python3Minimal ];
  programs.zsh = {
    # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/alias-finder
    # https://github.com/MichaelAquilina/zsh-you-should-use/issues/120
    antidote.plugins = [ "djui/alias-tips" ];
    initContent = lib.mkOrder 800 ''
      # https://github.com/djui/alias-tips/blob/41cb143ccc3b8cc444bf20257276cb43275f65c4/README.md#reveal-command
      ZSH_PLUGINS_ALIAS_TIPS_REVEAL=1
    '';
  };
} {
  programs.zsh = {
    antidote.plugins = [ "zsh-users/zsh-autosuggestions" ];
    initContent = lib.mkOrder 800 ''
      # https://github.com/zsh-users/zsh-autosuggestions/blob/85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5/README.md#suggestion-strategy
      ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion)

      # https://github.com/zsh-users/zsh-autosuggestions/issues/238#issuecomment-389324292
      pasteinit() {
        OLD_SELF_INSERT=''${''${(s.:.)widgets[self-insert]}[2,3]}
        zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
      }

      pastefinish() {
        zle -N self-insert $OLD_SELF_INSERT
      }
      zstyle :bracketed-paste-magic paste-init pasteinit
      zstyle :bracketed-paste-magic paste-finish pastefinish
    '';
  };
} {
  programs.zsh = {
    antidote.plugins = omzPluginPrefix [ "docker" ];
    initContent = lib.mkOrder 800 ''
      # https://github.com/ohmyzsh/ohmyzsh/tree/3e7ef0182f59c7990a52cf6ec2981adb56d5b368/plugins/docker
      zstyle ':completion:*:*:docker:*' option-stacking yes
      zstyle ':completion:*:*:docker-*:*' option-stacking yes
    '';
  };
}]

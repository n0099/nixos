extraModules:
{
  lib,
  pkgs,
  config,
  ...
}:

{
  imports = [ ./zsh.nix ] ++ extraModules;
  config = lib.mkMerge [
    {
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
          nvd
          dig
          ncdu
          file
          tree
          pv
          jq
          comma
        ];
      };
      services.ssh-agent.enable = true;
      programs = {
        nh.enable = true;
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
          extraConfig.push.autoSetupRemote = true;
          difftastic.enable = true;
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
        htop = {
          enable = true;
          settings = {
            hide_kernel_threads = false;
            hide_userland_threads = true;
            shadow_other_users = true;
            show_thread_names = true;
            highlight_changes = true;
            highlight_changes_delay_secs = 3;
            highlight_base_name = true;
            shadow_distribution_path_prefix = true;
            show_merged_command = true;
            header_margin = false;
            cpu_count_from_one = true;
            account_guest_in_cpu_meter = true;
            show_cpu_frequency = true;
            delay = 10;
            fields = with config.lib.htop.fields; [
              PID
              USER
              NLWP
              STATE
              # https://github.com/nix-community/home-manager/pull/7605
              # CTXT
              PERCENT_CPU
              PERCENT_MEM
              M_SIZE
              M_RESIDENT
              M_SHARE
              M_SWAP
              TIME
              STARTTIME
              COMM
            ];
          }
          // (
            # https://github.com/htop-dev/htop/blob/cfb561fd342c9d5d814ac4965a6047442994ba94/linux/Platform.c#L212
            with config.lib.htop;
            leftMeters [
              (graph "CPU")
              (text "CPU")
              (bar "AllCPUs2")
              (bar "LoadAverage")
            ]
          )
          // (
            with config.lib.htop;
            rightMeters [
              (graph "Memory")
              (text "Memory")
              (bar "Memory")
              (bar "Swap")
              (bar "Zram")
              (text "Tasks")
              (text "Uptime")
            ]
          );
        };
      };
    }
  ];
}

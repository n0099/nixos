{
  flake.modules = {
    nixos.htop.systemd.tmpfiles.settings.htoprc =
      let
        htoprc = ".config/htop/htoprc";
      in
      {
        "/root/${htoprc}"."L+".argument = "/home/n0099/${htoprc}"; # let `sudo htop` use the same config
      };
    homeManager.htop =
      { config, ... }:

      {
        programs.htop = {
          enable = true;
          settings = {
            hide_kernel_threads = false;
            hide_userland_threads = true;
            shadow_other_users = true;
            show_thread_names = true;
            show_program_path = false; # workaround for https://github.com/htop-dev/htop/pull/1789
            highlight_changes = true;
            highlight_changes_delay_secs = 3;
            highlight_base_name = true;
            shadow_distribution_path_prefix = true;
            show_merged_command = true;
            header_margin = false;
            cpu_count_from_one = true;
            detailed_cpu_time = true;
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
  };
}

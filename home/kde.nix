{ lib, pkgs, ... }:

{
  programs.plasma = lib.mkMerge [
    # run `~/.local/share/plasma-manager/run_all.sh` after `nixos-rebuild switch` to restart plasma-shell and apply settings
    {
      enable = true;
      overrideConfig = true;
    }
    {
      panels = [
        {
          floating = true;
          lengthMode = "fit";
          opacity = "translucent";
          widgets = [
            # https://github.com/nix-community/plasma-manager/tree/d47428e5390d6a5a8f764808a4db15929347cd77/modules/widgets
            { kickoff.icon = "nix-snowflake"; } # https://discuss.kde.org/t/need-help-to-find-the-names-locations-of-certain-icons/33988
            { pager = { }; }
            {
              iconTasks = {
                iconsOnly = false; # https://github.com/nix-community/plasma-manager/issues/473#issuecomment-2708983491
                launchers = [
                  # https://develop.kde.org/docs/plasma/scripting/keys/
                  "preferred://filemanager"
                  "preferred://browser"
                  "applications:org.kde.konsole.desktop"
                ];
              };
            }
            "org.kde.plasma.marginsseparator"
            { systemTray = { }; }
            {
              digitalClock = {
                date.format = "isoDate";
                time = {
                  format = "24h";
                  showSeconds = "always";
                };
                calendar = {
                  firstDayOfWeek = "monday";
                  showWeekNumbers = true;
                };
              };
            }
            "org.kde.plasma.showdesktop"
          ];
        }
      ];
    }
  ];
  programs.konsole = {
    enable = true;
    defaultProfile = "default";
    profiles.default = {
      font = {
        name = "FiraCode Nerd Font Ret";
        size = 11; # https://github.com/nix-community/plasma-manager/pull/529
      };
      extraConfig = {
        Appearance.UseFontLineChararacters = true;
        General = {
          DimWhenInactive = true;
          TerminalColumns = 80;
          TerminalRows = 24;
        };
        "Interaction Options" = {
          AutoCopySelectedText = true;
          TrimLeadingSpacesInSelectedText = true;
          TrimTrailingSpacesInSelectedText = true;
        };
        Scrolling.HistorySize = 5000;
      };
    };
    extraConfig = {
      KonsoleWindow = {
        AllowMenuAccelerators = false;
        RememberWindowSize = false;
        ShowWindowTitleOnTitleBar = true;
      };
      MainWindow.MenuBar = true;
      TabBar = {
        CloseTabOnMiddleMouseButton = true;
        NewTabButton = true;
      };
      SplitView.SplitViewVisibility = "AlwaysHideSplitHeader";
    };
  };
}

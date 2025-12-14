{ lib, pkgs, ... }:

lib.mkMerge [
  {
    programs.plasma = lib.mkMerge [
      # run `~/.local/share/plasma-manager/run_all.sh` after `nixos-rebuild switch` to restart plasma-shell and apply settings
      {
        enable = true;
        overrideConfig = true;
      }
      {
        # https://danbooru.donmai.us/posts?tags=minuo+ratio%3A16%3A9
        workspace = {
          wallpaperFillMode = "preserveAspectFit";
          wallpaper = (
            (pkgs.fetchurl {
              url = "https://cdn.donmai.us/original/cb/bf/__doremy_sweet_and_kana_anaberal_touhou_drawn_by_minuo__cbbf70a927d77d9630c1cb00fe4ca300.png";
              hash = "sha256-V4Lde1mL7Knq1PCqBdTGbQYPdutaDeNeGqHtB7P1b8g=";
            }).outPath
          );
        };
        kscreenlocker.appearance.wallpaper =
          (pkgs.fetchurl {
            url = "https://cdn.donmai.us/original/06/03/__patchouli_knowledge_koakuma_kaku_seiga_hieda_no_akyuu_and_motoori_kosuzu_touhou_drawn_by_minuo__0603e0e274622ad12b048db4470f5bb4.jpg";
            hash = "sha256-6DqmS10XBjqWFPE+bJD4ZJSWSRQdXNfQDw+tb1zqofo=";
          }).outPath;
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
  }
  {
    programs.plasma.workspace.splashScreen.theme = "minecraftworldloading-kde-splash";
    xdg.dataFile."plasma/look-and-feel/minecraftworldloading-kde-splash" = {
      enable = true;
      source =
        (pkgs.fetchFromGitHub {
          owner = "Samsu-F";
          repo = "minecraftworldloading-kde-splash";
          rev = "db3dcf5751afe795d92eec80ff83a16222ca2a18";
          hash = "sha256-XqzjrHjBDV1xTWQjZ0A4MAu6BlHqlEPNkk/48PjBZEI=";
        }).outPath;
    };
  }
  {
    programs.konsole = {
      enable = true;
      defaultProfile = "default";
      profiles.default = {
        font = {
          name = "FiraCode Nerd Font Ret";
          size = 11;
        };
        extraConfig = {
          Appearance.UseFontLineChararacters = true;
          General = {
            DimWhenInactive = true;
            TerminalColumns = 80;
            TerminalRows = 24;
          };
          "Interaction Options".AutoCopySelectedText = true;
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
    # https://github.com/nix-community/plasma-manager/issues/327
    # https://forum.manjaro.org/t/after-last-update-konsole-keyboard-shortcut-issue-with-alt-f/161923
    # https://bugs.kde.org/show_bug.cgi?id=482628
  }
  {
    programs.librewolf = {
      profiles.default.extensions.packages = [
        pkgs.nur.repos.rycee.firefox-addons.plasma-integration
      ];
      nativeMessagingHosts = [ pkgs.kdePackages.plasma-browser-integration ];
    };
  }
  {
    programs.plasma.powerdevil.AC = {
      autoSuspend.action = "nothing";
      powerProfile = "performance";
    };
  }
  {
    programs.plasma.configFile.baloofilerc."Basic Settings"."Indexing-Enabled" = false;
  }
]

{ inputs, ... }:

{
  flake.modules.homeManager = {
    nur = inputs.nur.modules.homeManager.default;
    librewolf =
      {
        lib,
        pkgs,
        config,
        osConfig,
        ...
      }:

      let
        addons = pkgs.nur.repos.rycee.firefox-addons;
        mkPreferences = lib.mapAttrs (
          _: value: {
            Value = value;
            Status = "locked";
          }
        );
      in
      {
        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "x-scheme-handler/http" = "librewolf.desktop";
            "x-scheme-handler/https" = "librewolf.desktop";
          };
        };
        programs.librewolf = lib.mkMerge [
          {
            enable = true;
            settings =
              # https://github.com/mozilla/policy-templates/issues/1101
              {
                "sidebar.revamp" = true;
                "sidebar.verticalTabs" = true;
              }
              // {
                "privacy.resistFingerprinting.letterboxing" = true; # https://old.reddit.com/r/TOR/comments/ebwcte/does_changing_the_window_size_still_reduce_my/
              }
              // {
                # https://librewolf.net/docs/settings/#enable-autoscroll-safely
                # https://gitlab.com/librewolf-community/browser/windows/-/issues/103
                "middlemouse.paste" = false;
                "general.autoScroll" = true;
              };
            policies = {
              Proxy = {
                Mode = "manual";
                SOCKSProxy = 1 |> lib.elemAt (lib.splitString "://" osConfig.networking.proxy.default);
              };
              DisplayBookmarksToolbar = "never";
              Homepage.StartPage = "previous-session";
              SanitizeOnShutdown = {
                Locked = true;
                Cache = false;
                Cookies = false;
                # https://old.reddit.com/r/firefox/comments/7s111d/how_do_i_clear_downloads_automatically_when/
                # https://bugzilla.mozilla.org/show_bug.cgi?id=857402
                # Downloads = true;
              };
              Preferences = mkPreferences (
                # about:policies
                # https://mozilla.github.io/policy-templates
                # https://github.com/mozilla/policy-templates
                # https://github.com/NixOS/nixpkgs/blob/b4c2c57c31e68544982226d07e4719a2d86302a8/nixos/modules/programs/firefox.nix#L340-L345
                {
                  "browser.urlbar.trimURLs" = false;
                  "widget.gtk.overlay-scrollbars.enabled" = false; # https://superuser.com/questions/1720362/firefox-scroll-bar-disappearing
                }
                // lib.concatMapAttrs (name: value: { "browser.newtabpage.activity-stream.${name}" = value; }) {
                  "feeds.topsites" = true;
                  "section.highlights.includeBookmarks" = false;
                  "section.highlights.includeDownloads" = true;
                  "section.highlights.includeVisited" = true;
                  "feeds.section.highlights" = true;
                  "section.highlights.rows" = 4;
                  "topSitesRows" = 4;
                  "showSponsoredCheckboxes" = false;
                }
                // {
                  "browser.download.autohideButton" = true;
                  "browser.download.alwaysOpenPanel" = true;
                }
                // {
                  "browser.translations.automaticallyPopup" = false;
                }
                // {
                  # https://old.reddit.com/r/firefox/comments/18z7jp5/issues_with_policiesjson/
                  "browser.uiCustomization.state" = builtins.toJSON {
                    placements = {
                      nav-bar = [
                        "sidebar-button"
                        "alltabs-button"
                        "firefox-view-button"
                        "back-button"
                        "forward-button"
                        "stop-reload-button"
                        "vertical-spacer"
                        "urlbar-container"
                        "fxa-toolbar-menu-button"
                        "ublock0_raymondhill_net-browser-action"
                        "canvasblocker_kkapsner_de-browser-action"
                        "_74145f27-f039-47ce-a470-a662b129930a_-browser-action"
                        "_39919541-b8e1-4e50-a249-043d2326ef5e_-browser-action"
                        "jid0-3guet1r69sqnsrca5p8kx9ezc3u_jetpack-browser-action"
                        "wayback_machine_mozilla_org-browser-action"
                        "_07c6b8e1-94f7-4bbf-8e91-26c0a8992ab5_-browser-action"
                        "_b2dbb4cf-7425-4790-8bc4-b1ccbc818118_-browser-action"
                        "osds_openlinksw_com-browser-action"
                        "_aecec67f-0d10-4fa7-b7c7-609a2db280cf_-browser-action"
                        "unified-extensions-button"
                        "downloads-button"
                      ];
                    };
                    seen = [
                      "_3c078156-979c-498b-8990-85f7987dd929_-browser-action"
                      "sponsorblocker_ajay_app-browser-action"
                    ];
                    currentVersion = 23;
                  };
                }
              );
            };
          }
          {
            policies = {
              ExtensionUpdate = false; # disable auto update https://support.mozilla.org/en-US/questions/952162
              ExtensionSettings =
                (lib.genAttrs
                  (config.programs.librewolf.profiles.default.extensions.packages |> map (pkg: pkg.addonId))
                  (addonId: {
                    installation_mode = "normal_installed";
                    install_url = "~/.librewolf/default/extensions/${addonId}.xpi"; # given this and `installation_mode` will prevent this extension being removed
                    updates_disabled = true; # disable auto and prevent manually update in `about:addons`
                  })
                )
                // {
                  "*" = {
                    installation_mode = "blocked"; # this won't prevent update extensions managed by home-manager via manually re-install them from AMO
                    blocked_install_message = "Please use home-manager to manage extensions.";
                  };
                };
            };
          }
          {
            profiles.default.extensions.packages = with addons; [
              bitwarden
              refined-github
              react-devtools
              vue-js-devtools
              wayback-machine
              terms-of-service-didnt-read
              offline-qr-code-generator
              hover-zoom-plus
              violentmonkey
              copy-selection-as-markdown
              clearurls
              promnesia

              annotations-restored
              old-reddit-redirect
              reddit-enhancement-suite
              steam-database
              sponsorblock
              single-file
              return-youtube-dislikes
              tab-session-manager
              indie-wiki-buddy
              canvasblocker
              decentraleyes
              (addons.buildFirefoxXpiAddon {
                pname = "dimensions";
                version = "2.1.1resigned1";
                addonId = "{38300720-a4e6-4463-a5d4-d3e981959f59}";
                url = "https://addons.mozilla.org/firefox/downloads/file/4271727";
                sha256 = "sha256-g77jPBZ9ndLBC+Oyd6d0Df1dQ18T3I7wMGx7Dekaww4=";
                meta = { };
              })
              (addons.buildFirefoxXpiAddon {
                pname = "entity-explosion";
                version = "0.9.6";
                addonId = "{b2dbb4cf-7425-4790-8bc4-b1ccbc818118}";
                url = "https://addons.mozilla.org/firefox/downloads/file/4281112";
                sha256 = "sha256-2f1QCh7tC8lq/g3oE9CA/SVId0EuviA3alM2EwIOgvI=";
                meta = { };
              })
              (addons.buildFirefoxXpiAddon {
                pname = "undisposition-racle-fork";
                version = "0.0.6";
                addonId = "{39919541-b8e1-4e50-a249-043d2326ef5e}";
                url = "https://addons.mozilla.org/firefox/downloads/file/4019924";
                sha256 = "sha256-cIk2Fx4YMIoAXcaGJKoSyvKQ9k6/GJ1sLn0ZuxrOcLw=";
                meta = { };
              })
              (addons.buildFirefoxXpiAddon {
                pname = "view-background-images";
                version = "3.0.4";
                addonId = "{f1f7b448-d666-46c6-9dfa-3ee4c5c83578}";
                url = "https://addons.mozilla.org/firefox/downloads/file/4313867";
                sha256 = "sha256-k0cvoatpeiiHlY/+71ViNot92bJGn8avBruDmzVCaoo=";
                meta = { };
              })
              (addons.buildFirefoxXpiAddon {
                pname = "openlink-structured-data-sniff";
                version = "3.4.27";
                addonId = "osds@openlinksw.com";
                url = "https://addons.mozilla.org/firefox/downloads/file/4558089";
                sha256 = "sha256-KCDvs2cbz24gMIjA8B4XwfPznckta2tWozgHDxnYrq0=";
                meta = { };
              })
              (addons.buildFirefoxXpiAddon {
                pname = "markdown-here";
                version = "2.16.0";
                addonId = "markdown-here-webext@adam.pritchard";
                url = "https://addons.mozilla.org/firefox/downloads/file/4530942";
                sha256 = "sha256-EAlgm9Vg1x+PNd6G4ogoLnAa0AP8WhJ/keL7PSPqLnc=";
                meta = { };
              })
              (addons.buildFirefoxXpiAddon {
                pname = "copy-unicode-urls";
                version = "0.0.21";
                addonId = "{ec113e08-3560-4792-a123-26355ac2d26d}";
                url = "https://addons.mozilla.org/firefox/downloads/file/4154565";
                sha256 = "sha256-kBupwPnSjk4Z5dyFy0jJSFM5fGcFIGxz6X2Op6Ca38w=";
                meta = { };
              })
              (addons.buildFirefoxXpiAddon {
                pname = "github-user-languages";
                version = "1.1.0";
                addonId = "extension@github-user-languages.github.com";
                url = "https://addons.mozilla.org/firefox/downloads/file/4172660";
                sha256 = "sha256-210XZ4l106wpqQriBKzygC41f9BFW95bTAclZKQof8w=";
                meta = { };
              })
              (addons.buildFirefoxXpiAddon {
                pname = "whowrotethat";
                version = "0.22.3.0";
                addonId = "{7c53a467-2542-497a-86fb-59c2904a56d1}";
                url = "https://addons.mozilla.org/firefox/downloads/file/4494744";
                sha256 = "sha256-G8W+ZB5iJsBYXhcn9AZFWwiYwLWjwPuSfK+5I4vEZNw=";
                meta = { };
              })
              (addons.buildFirefoxXpiAddon {
                pname = "youtube-tweak";
                version = "1.1.4";
                addonId = "youtubetweak@dark495.me";
                url = "https://addons.mozilla.org/firefox/downloads/file/4634049";
                sha256 = "sha256-f1RyLq8yMwckNEVgHRBqqxEdOnUUW6AiT0AtlG9ARZc=";
                meta = { };
              })
              /*
                (addons.buildFirefoxXpiAddon {
                  # https://github.com/nix-community/nur-combined/blob/c0b354b97973b08cd9e55ca81e95fcfb16f93f5a/repos/rycee/pkgs/firefox-addons/default.nix#L9-L41
                  pname = "";
                  version = "";
                  addonId = "";
                  url = "";
                  sha256 = "";
                  meta = { };
                })
              */
            ];
          }
          {
            profiles.default.extensions.packages = [ addons.ublock-origin ];
            # https://mozilla.github.io/policy-templates/#3rdparty
            # https://discourse.nixos.org/t/declare-firefox-extensions-and-settings/36265/26
            # click `Reset to default settings…` in moz-extension://95bd60a3-bbff-4694-a503-b7f8d4a3e9e6/dashboard.html#settings.html is required after managed storage changed
            policies."3rdparty".Extensions."uBlock0@raymondhill.net".adminSettings = {
              userSettings = {
                suspendUntilListsAreLoaded = true;
                advancedUserEnabled = true;
              };
              selectedFilterLists = [
                "user-filters"
              ]
              ++ [
                "ublock-filters"
                "ublock-badware"
                "ublock-privacy"
                "ublock-quick-fixes"
                "ublock-unbreak"
                "ublock-experimental"
              ]
              ++ [
                "easylist"
                "adguard-generic"
                "adguard-mobile"
              ]
              ++ [
                "easyprivacy"
                "LegitimateURLShortener"
                "adguard-spyware-url"
                # "block-lan"
              ]
              ++ [
                "urlhaus-1"
                "curben-phishing"
              ]
              ++ [
                "plowe-0"
                "dpollock-0"
              ]
              ++ [
                "fanboy-cookiemonster"
                "ublock-cookies-easylist"
              ]
              ++ [
                "adguard-cookies"
                "ublock-cookies-adguard"
              ]
              ++ [
                "fanboy-social"
                "adguard-social"
                "fanboy-thirdparty_social"
              ]
              ++ [
                "easylist-chat"
                "easylist-newsletters"
                "easylist-notifications"
                "easylist-annoyances"
                "adguard-mobile-app-banners"
                "adguard-other-annoyances"
                "adguard-popup-overlays"
                "adguard-widgets"
                "ublock-annoyances"
              ]
              ++ [
                "ALB-0"
                "BGR-0"
                "CHN-0"
                "CZE-0"
                "DEU-0"
                "EST-0"
                "ara-0"
                "spa-1"
                "spa-0"
                "FIN-0"
                "FRA-0"
                "GRC-0"
                "HRV-0"
                "HUN-0"
                "IDN-0"
                "ISR-0"
                "IND-0"
                "IRN-0"
                "ISL-0"
                "ITA-0"
                "JPN-1"
                "KOR-1"
                "LTU-0"
                "LVA-0"
                "MKD-0"
                "NLD-0"
                "NOR-0"
                "POL-0"
                "ROU-1"
              ]
              ++ [
                "RUS-0"
                "RUS-1"
              ]
              ++ [
                "SWE-1"
                "SVN-0"
                "THA-0"
                "TUR-0"
                "UKR-0"
                "VIE-1"
              ];
            };
          }
          {
            profiles.default.extensions.packages = [ addons.sidebery ];
            policies."3rdparty".Extensions."{3c078156-979c-498b-8990-85f7987dd929}".settings = {
              # https://github.com/mbnuqw/sidebery/blob/b6fbb138614267a5cb9bf0757e8cd2e99a63f8b4/src/services/settings.actions.ts#L26-L29
              # delete item `settings` in moz-extension://d244b345-7b9d-4203-aaaa-564dd6bb0339/page.setup/setup.html#storage is required after managed storage changed
              nativeScrollbarsThin = false;
              dndOutside = "data";
              searchBarMode = "static";
              tabsUnreadMark = true;
              warnOnMultiTabClose = "none";
              moveNewTab = "after";
              colorizeTabs = true;
              previewTabs = true;
              previewTabsPopupWidth = 512;
              previewTabsTitle = 10;
              previewTabsUrl = 10;
              density = "loose";
              scrollThroughTabs = "global";
              scrollThroughTabsCyclic = true;
              tabsSecondClickActPrev = true;
              syncUseFirefox = false;
            };
          }
          {
            policies.Preferences = mkPreferences {
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            };
            profiles.default.userChrome = ''
              #sidebar-panel-header {
                /* https://github.com/piroor/treestyletab/wiki/Code-snippets-for-custom-style-rules#hide-the-tree-style-tab-header-at-the-top-of-the-sidebar */
                display: none;
              }
            '';
          }
          {
            profiles.default = {
              extensions.packages = [ addons.kiss-translator ];
              userContent = ''
                kiss-translator {
                  display: inline-block;
                  outline: dashed darkgray 1px;
                  padding: 0.25rem;
                  font-language-override: "ZHS";
                }
                kiss-translator > br {
                  display: none;
                }
              '';
            };
          }
          {
            profiles.default.search = {
              force = true; # https://github.com/nix-community/home-manager/issues/3698
              privateDefault = "ddg";
            };
          }
          {
            profiles.default.search.engines =
              lib.concatMapAttrs # https://github.com/nix-community/home-manager/blob/75ed713570ca17427119e7e204ab3590cc3bf2a5/modules/programs/firefox/profiles/search.nix#L498-L524
                (type: alias: {
                  "nix-${type}" = {
                    name = "Nix ${type}";
                    urls = [
                      {
                        template = "https://search.nixos.org/${type}";
                        params = [
                          {
                            name = "query";
                            value = "{searchTerms}";
                          }
                        ];
                      }
                    ];
                    icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                    definedAliases = [ alias ];
                  };
                })
                {
                  packages = "@np";
                  options = "@no";
                };
          }
          {
            profiles.default.search =
              let
                alias = "kagi";
              in
              {
                default = alias;
                engines.kagi = {
                  name = "Kagi";
                  urls = [
                    {
                      template = "https://kagi.com/search";
                      params = [
                        {
                          name = "q";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];
                  icon = pkgs.fetchurl {
                    url = "https://kagi.com/apple-touch-icon.png";
                    hash = "sha256-1XQib7Lok2vCZpm7jr0Tqzy7ZcLZ5epLGFTjf7y8gps=";
                  };
                  definedAliases = [ "@${alias}" ];
                };
              };
          }
        ];
      };
  };
}

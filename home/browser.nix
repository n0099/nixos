{ lib, pkgs, ... }:

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
  programs.librewolf = lib.mkMerge [
    {
      enable = true;
      profiles.default.extensions.packages = with addons; [
        bitwarden
        refined-github
        react-devtools
        vue-js-devtools
        wayback-machine
        terms-of-service-didnt-read
        plasma-integration
        offline-qr-code-generator
        hover-zoom-plus
        greasemonkey
        copy-selection-as-markdown
        clearurls
        promnesia
      ];
      policies = {
        DisplayBookmarksToolbar = "newtab";
        Homepage.StartPage = "previous-session";
        SanitizeOnShutdown = {
          Locked = true;
          Cache = false;
          Cookies = false;
        };
        Preferences = mkPreferences (
          # about:policies
          # https://mozilla.github.io/policy-templates
          # https://github.com/mozilla/policy-templates
          # https://github.com/NixOS/nixpkgs/blob/b4c2c57c31e68544982226d07e4719a2d86302a8/nixos/modules/programs/firefox.nix#L340-L345
          {
            "sidebar.revamp" = true;
            "sidebar.verticalTabs" = true;
          }
          // {
            "browser.urlbar.trimURLs" = false;
          }
          // {
            "browser.newtabpage.activity-stream.feeds.topsites" = true;
            "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
            "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = true;
            "browser.newtabpage.activity-stream.section.highlights.includeVisited" = true;
            "browser.newtabpage.activity-stream.feeds.section.highlights" = true;
            "browser.newtabpage.activity-stream.section.highlights.rows" = 4;
            "browser.newtabpage.activity-stream.topSitesRows" = 4;
            "browser.newtabpage.activity-stream.showSponsoredCheckboxes" = false;
          }
        );
      };
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
      profiles.default.extensions.packages = [
        (addons.buildFirefoxXpiAddon {
          # https://github.com/nix-community/nur-combined/blob/c0b354b97973b08cd9e55ca81e95fcfb16f93f5a/repos/rycee/pkgs/firefox-addons/default.nix#L9-L41
          pname = "sidebery";
          # https://github.com/mbnuqw/sidebery/pull/2016
          # https://github.com/mbnuqw/sidebery/commit/86eb0ae2019ebb8b5557fd535e689624503bc1d6
          version = "5.3.3.21";
          addonId = "{3c078156-979c-498b-8990-85f7987dd929}";
          url = "https://github.com/mbnuqw/sidebery/releases/download/v5.3.3/sidebery-5.3.3.21.xpi";
          sha256 = "sha256-K3EktiWCCQtlzfVWc1T5LlT2dXwAL1gWsqRloHQHCtM=";
          meta = addons.sidebery.meta;
        })
      ];
      policies."3rdparty".Extensions."{3c078156-979c-498b-8990-85f7987dd929}".settings = {
        # https://github.com/mbnuqw/sidebery/blob/b6fbb138614267a5cb9bf0757e8cd2e99a63f8b4/src/services/settings.actions.ts#L26-L29
        nativeScrollbarsThin = false;
        dndOutside = "data";
        searchBarMode = "static";
        activateAfterClosing = "prev_act";
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
  ];
}

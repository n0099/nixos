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

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
  ];
}

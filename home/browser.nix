{ lib, pkgs, ... }:

let
  addons = pkgs.nur.repos.rycee.firefox-addons;
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
    }
  ];
}

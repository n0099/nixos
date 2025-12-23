{ inputs, ... }:

{
  flake.modules = {
    nixos.nur = inputs.nur.modules.nixos.default;
    homeManager = {
      librewolf-plasma-integration =
        { pkgs, ... }:

        {
          programs.librewolf = {
            profiles.default.extensions.packages = [
              pkgs.nur.repos.rycee.firefox-addons.plasma-integration
            ];
            nativeMessagingHosts = [ pkgs.kdePackages.plasma-browser-integration ];
          };
        };
    };
  };
}

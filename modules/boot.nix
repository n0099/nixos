{
  flake.modules.nixos.boot =
    { config, inputs, ... }:

    {
      imports = [ inputs.minegrub-world-sel-theme.nixosModules.default ];
      boot.loader = {
        grub = {
          minegrub-world-sel = {
            enable = true;
            customIcons = with config.system; [
              # https://github.com/Lxtharia/minegrub-world-sel-theme/pull/33
              {
                inherit name;
                lineTop = with nixos; "${distroName} ${codeName} (${version})";
                lineBottom = "Survival Mode, No Cheats, Version: ${nixos.release}";
                imgName = "nixos";
              }
            ];
          };
          extraEntries = /* bash */ ''
            menuentry 'UEFI Setup' --class uefi {
              # https://github.com/Lxtharia/minegrub-world-sel-theme/blob/00254ae5e1836ede1ad502b74dac162eab8eebe2/README.md#setting-icons-for-entries-like-uefi-settings
              fwsetup
            }
          '';
        };
      };
    };
}

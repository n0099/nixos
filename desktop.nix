{
  config,
  lib,
  ...
}:

{
  config = lib.mkMerge [
    {
      services = {
        xserver.enable = true;
        displayManager.sddm.enable = true;
        desktopManager.plasma6.enable = true;
      };
    }
    {
      security.rtkit.enable = true;
      services = {
        pulseaudio.enable = false;
        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };
      };
    }
    {
      networking.networkmanager.enable = true;
    }
  ];
}

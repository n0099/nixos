{
  config,
  lib,
  pkgs,
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
      nixpkgs.config.allowUnfreePredicate =
        pkg:
        lib.elem (lib.getName pkg) [
          "nvidia-x11"
          "nvidia-settings"
        ];
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        open = true;
        package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
          # https://github.com/NixOS/nixpkgs/issues/416023#issuecomment-3109657947
          version = "575.64.03";
          sha256_64bit = "sha256-S7eqhgBLLtKZx9QwoGIsXJAyfOOspPbppTHUxB06DKA=";
          openSha256 = "sha256-SAl1+XH4ghz8iix95hcuJ/EVqt6ylyzFAao0mLeMmMI=";
          settingsSha256 = "sha256-o8rPAi/tohvHXcBV+ZwiApEQoq+ZLhCMyHzMxIADauI=";
          persistencedSha256 = "sha256-/3OAZx8iMxQLp1KD5evGXvp0nBvWriYapMwlMSc57h8=";
        };
        powerManagement.enable = true; # https://wiki.nixos.org/wiki/NVIDIA#Graphical_corruption_and_system_crashes_on_suspend/resume
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
    {
      fonts = {
        packages = with pkgs; [
          nerd-fonts.fira-code
          source-han-sans-vf-otf
        ];
        fontconfig = {
          enable = true;
          localConf = ''
            <match target="font">
              <!-- https://discuss.kde.org/t/konsole-renders-btop-characters-not-properly/12502 -->
              <!-- https://stackoverflow.com/questions/47501411/how-to-set-font-per-unicode-range-codepoint-in-fontconfig/47614324#47614324 -->
              <!-- https://github.com/cjbassi/ytop/issues/79#issuecomment-676070893 -->
              <test name="family" compare="eq">
                <string>FreeMono</string>
              </test>
              <edit name="charset" mode="assign">
                <minus>
                  <name>charset</name>
                  <charset>
                    <range>
                      <!-- https://codepoints.net/braille_patterns -->
                      <int>0x2800</int>
                      <int>0x28FF</int>
                    </range>
                  </charset>
                </minus>
              </edit>
            </match>
          '';
        };
      };
    }
  ];
}

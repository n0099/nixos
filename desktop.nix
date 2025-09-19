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
          # $ version=xxx.xx.xx sh -xc 'nix store prefetch-file https://download.nvidia.com/XFree86/Linux-x86_64/${version}/NVIDIA-Linux-x86_64-${version}.run && echo open-gpu-kernel-modules nvidia-{settings,persistenced} | tr " " "\n" | xargs -I{} , nix-prefetch-github NVIDIA {} --rev $version'
          version = "580.82.09";
          sha256_64bit = "sha256-Puz4MtouFeDgmsNMKdLHoDgDGC+QRXh6NVysvltWlbc=";
          openSha256 = "sha256-YB+mQD+oEDIIDa+e8KX1/qOlQvZMNKFrI5z3CoVKUjs=";
          settingsSha256 = "sha256-um53cr2Xo90VhZM1bM2CH4q9b/1W2YOqUcvXPV6uw2s=";
          persistencedSha256 = "sha256-lbYSa97aZ+k0CISoSxOMLyyMX//Zg2Raym6BC4COipU=";
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
      fonts = lib.mkMerge [
        {
          packages = with pkgs; [
            nerd-fonts.fira-code
            last-resort
          ];
          fontconfig.enable = true;
          fontconfig.localConf = ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
            <fontconfig>
          '';
        }
        {
          fontconfig.localConf = ''
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
        }
        {
          packages = with pkgs; [
            # source-sans
            source-han-sans
            # source-han-sans-vf-otf
            # source-serif
            source-han-serif
            # source-han-serif-vf-otf
            # source-code-pro
            source-han-mono
          ];
          fontconfig.localConf = ''
            <!-- https://gist.github.com/akiirui/b3f36e8bdf9a9f5636a98113960bc7f4 -->
            <!-- https://japanese.stackexchange.com/questions/86411/why-are-%E5%85%B3-and-%E5%A4%8D-half-width-in-japanese -->
            <match target="pattern">
              <test name="family">
                <string>serif</string>
              </test>
              <edit name="family" mode="append" binding="strong">
                <string>Source Han Serif SC</string>
              </edit>
            </match>
            <match target="pattern">
              <test name="family">
                <string>sans-serif</string>
              </test>
              <edit name="family" mode="append" binding="strong">
                <string>Source Han Sans SC</string>
              </edit>
            </match>
            <match target="pattern">
              <test name="family">
                <string>monospace</string>
              </test>
              <edit name="family" mode="append" binding="strong">
                <string>Source Han Mono SC</string>
              </edit>
            </match>
          '';
        }
        {
          fontconfig.localConf = "</fontconfig>";
        }
      ];
    }
  ];
}

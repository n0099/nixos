{
  config,
  lib,
  pkgs,
  ...
}:

lib.mkMerge [
  {
    services = {
      xserver.enable = true;
      displayManager.sddm.enable = true;
      desktopManager.plasma6.enable = true;
    };
  }
  {
    boot = {
      kernelPackages = pkgs.linuxPackagesFor (
        pkgs.linuxKernel.kernels.linux_lqx.override {
          # wait for zfs 2.4 to support kernel up to 6.17
          # https://wiki.nixos.org/wiki/Linux_kernel#Pinning_a_kernel_version
          argsOverride =
            let
              version = "6.16.12";
              versionWithSuffix = "${version}-lqx1"; # https://github.com/NixOS/nixpkgs/blob/ca534a76c4afb2bdc07b681dbc11b453bab21af8/pkgs/os-specific/linux/kernel/zen-kernels.nix#L27
            in
            {
              src = pkgs.fetchFromGitHub {
                owner = "zen-kernel";
                repo = "zen-kernel";
                rev = "v${versionWithSuffix}";
                hash = "sha256-Phagc5ua8mwbvZEwEvJmUPR4g5geYqs65dYXj9PXFW8=";
              };
              inherit version;
              modDirVersion = versionWithSuffix;
            };
        }
      );
      kernelPatches = [
        {
          name = "PREEMPT_RT";
          patch = null;
          structuredExtraConfig = {
            PREEMPT_RT = lib.kernel.yes;
            PREEMPT_VOLUNTARY = lib.mkForce lib.kernel.unset; # https://github.com/NixOS/nixpkgs/blob/d2ed99647a4b195f0bcc440f76edfa10aeb3b743/pkgs/os-specific/linux/kernel/common-config.nix#L1304
          }
          // lib.genAttrs [
            # https://realtime-linux.org/getting-started-with-preempt_rt-guide/
            # https://www.osadl.org/fileadmin/dam/presentations/COOL-03-2023/COOL-2023-03_Configuration-of-the-Linux-PREEMPT_RT-Kernel_Alexander-Baehr.pdf
            # "DEBUG_LOCKDEP"
            "DEBUG_PREEMPT"
            "DEBUG_OBJECTS"
            "SLUB_DEBUG"
          ] (_: lib.kernel.no);
        }
        {
          name = "DRM_I915_GVT";
          patch = null;
          structuredExtraConfig = lib.genAttrs [ "DRM_I915_GVT" "DRM_I915_GVT_KVMGT" ] (
            # https://wiki.nixos.org/wiki/Linux_kernel#Custom_configuration
            _: lib.mkForce lib.kernel.unset
          );
        }
      ];
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
        version = "570.195.03";
        sha256_64bit = "sha256-1H3oHZpRNJamCtyc+nL+nhYsZfJyL7lgxPUxvXrF3B4=";
        openSha256 = "sha256-vCBB/UJgVKHlSEWdgoF45lODr3YJmR6JwjrwWgWszBw=";
        settingsSha256 = "sha256-mjKkMEPV6W69PO8jKAKxAS861B82CtCpwVTeNr5CqUY=";
        persistencedSha256 = "sha256-BMpo2PIabhHjZQqUQi/W5DYhgAPmfCdFvXdN6ND2Bfs=";
        patchesOpen = [
          (pkgs.writeText "PREEMPT_RT.patch"
            # https://forums.developer.nvidia.com/t/inquiries-regarding-nvidias-support-for-preempt-rt/283007
            ''
              diff --git a/kernel-open/conftest.sh b/kernel-open/conftest.sh
              index 7de4f4af..e3d65c9a 100755
              --- a/kernel-open/conftest.sh
              +++ b/kernel-open/conftest.sh
              @@ -5057,10 +5057,7 @@ case "$5" in
                       #
                       VERBOSE=$6
              -
              -        if [ -n "$IGNORE_PREEMPT_RT_PRESENCE" ]; then
              -            exit 0
              -        fi
              +        exit 0

                       if test_configuration_option CONFIG_PREEMPT_RT; then
                           PREEMPT_RT_PRESENT=1
                       elif test_configuration_option CONFIG_PREEMPT_RT_FULL; then
            ''
          )
        ];
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
        pulse.enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
      };
    };
  }
  {
    networking.networkmanager.enable = true;
    environment.systemPackages = [ pkgs.wl-clipboard-rs ];
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
]

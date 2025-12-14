{
  flake.modules.nixos.desktop =
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
          kernelPackages =
            {
              # https://wiki.nixos.org/wiki/Linux_kernel#Pinning_a_kernel_version
              argsOverride =
                let
                  version = "6.17.11";
                  versionWithSuffix = "${version}-lqx1"; # https://github.com/NixOS/nixpkgs/blob/ca534a76c4afb2bdc07b681dbc11b453bab21af8/pkgs/os-specific/linux/kernel/zen-kernels.nix#L27
                in
                {
                  src = pkgs.fetchFromGitHub {
                    owner = "zen-kernel";
                    repo = "zen-kernel";
                    rev = "v${versionWithSuffix}";
                    hash = "sha256-Qulw4uBfHE9qOMiXdEsna+ko9QG7aZSM2mc6FXJ8lLY=";
                  };
                  inherit version;
                  modDirVersion = versionWithSuffix;
                };
            }
            |> pkgs.linuxKernel.kernels.linux_lqx.override
            |> pkgs.linuxPackagesFor;
          kernelPatches = [
            {
              name = "PREEMPT_RT";
              patch = null;
              structuredExtraConfig = {
                PREEMPT_RT = lib.kernel.yes;
                PREEMPT_VOLUNTARY = lib.kernel.unset |> lib.mkForce; # https://github.com/NixOS/nixpkgs/blob/d2ed99647a4b195f0bcc440f76edfa10aeb3b743/pkgs/os-specific/linux/kernel/common-config.nix#L1304
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
                _: lib.kernel.unset |> lib.mkForce
              );
            }
            {
              name = "SCHED_MUQSS";
              patch = null;
              # https://github.com/zen-kernel/zen-kernel/wiki/Detailed-Feature-List#muqss
              # https://lwn.net/Articles/720227/
              structuredExtraConfig.SCHED_MUQSS = lib.kernel.yes;
            }
          ];
        };
      }
      {
        n0099.permittedUnfreePackages = [
          "nvidia-x11"
          "nvidia-settings"
        ];
        services.xserver.videoDrivers = [ "nvidia" ];
        hardware.nvidia = {
          open = true;
          package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
            # https://github.com/NixOS/nixpkgs/issues/416023#issuecomment-3109657947
            # $ version=xxx.xx.xx sh -xc 'nix store prefetch-file https://download.nvidia.com/XFree86/Linux-x86_64/${version}/NVIDIA-Linux-x86_64-${version}.run && echo open-gpu-kernel-modules nvidia-{settings,persistenced} | tr " " "\n" | xargs -I{} , nix-prefetch-github NVIDIA {} --rev $version'
            version = "590.44.01";
            sha256_64bit = "sha256-VbkVaKwElaazojfxkHnz/nN/5olk13ezkw/EQjhKPms=";
            openSha256 = "sha256-ft8FEnBotC9Bl+o4vQA1rWFuRe7gviD/j1B8t0MRL/o=";
            settingsSha256 = "sha256-wVf1hku1l5OACiBeIePUMeZTWDQ4ueNvIk6BsW/RmF4=";
            persistencedSha256 = "sha256-nHzD32EN77PG75hH9W8ArjKNY/7KY6kPKSAhxAWcuS4=";
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
        n0099.permittedUnfreePackages = [
          # https://discourse.nixosstag.fcio.net/t/how-to-show-all-the-required-allowunfreepredicate-at-once/65816
          "cuda-merged"
          "cuda_cuobjdump"
          "cuda_gdb"
          "cuda_nvcc"
          "cuda_nvdisasm"
          "cuda_nvprune"
          "cuda_cccl"
          "cuda_cudart"
          "cuda_cupti"
          "cuda_cuxxfilt"
          "cuda_nvml_dev"
          "cuda_nvrtc"
          "cuda_nvtx"
          "cuda_profiler_api"
          "cuda_sanitizer_api"
          "libcublas"
          "libcufft"
          "libcurand"
          "libcusolver"
          "libnvjitlink"
          "libcusparse"
          "libnpp"
        ];
        environment.systemPackages = [ pkgs.nvtopPackages.nvidia ];
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
        hardware.bluetooth.enable = true;
        programs.kdeconnect.enable = true;
      }
      {
        networking.networkmanager.enable = true;
        environment.systemPackages = [ pkgs.wl-clipboard-rs ];
      }
      {
        powerManagement = {
          cpufreq.min = 5000000; # 5GHz
          resumeCommands = config.systemd.services.cpufreq.serviceConfig.ExecStart;
        };
      }
      {
        hardware.rasdaemon.enable = true;
      }
      {
        environment.systemPackages = [ pkgs.pcm ];
        boot.kernelModules = [ "msr" ];
      }
    ];
}

{
  flake.modules.nixos.desktop =
    {
      config,
      lib,
      pkgs,
      inputs,
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
        # https://discourse.nixos.org/t/chaotic-nyx-is-archved-what-are-some-alternatives/73073
        nixpkgs.overlays = [ inputs.nix-cachyos-kernel.outputs.overlay ]; # https://github.com/xddxdd/nix-cachyos-kernel/blob/dc3941ceb1cc0b303ddefc5e5fa1577a2d7856d7/flake.nix#L95
        boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto.extend (
          final: prev: {
            kernel = prev.kernel.override rec {
              # https://github.com/xddxdd/nix-cachyos-kernel/blob/dc3941ceb1cc0b303ddefc5e5fa1577a2d7856d7/kernel-cachyos/default.nix#L16
              version = "6.17.9";
              src = pkgs.fetchurl {
                url = "mirror://kernel/linux/kernel/v${lib.versions.major version}.x/linux-${version}.tar.xz";
                hash = "sha256-bQiAO5U8UJ30jUTTKB7TklJDIdi7NT6yHAVVeQyPjgY=";
              };
            };
          }
        ); # https://wiki.cachyos.org/features/kernel/#variants
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

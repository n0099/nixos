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
        networking.networkmanager.enable = true;
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
            version = "595.58.03";
            sha256_64bit = "sha256-jA1Plnt5MsSrVxQnKu6BAzkrCnAskq+lVRdtNiBYKfk=";
            openSha256 = "sha256-6LvJyT0cMXGS290Dh8hd9rc+nYZqBzDIlItOFk8S4n8=";
            settingsSha256 = "sha256-2vLF5Evl2D6tRQJo0uUyY3tpWqjvJQ0/Rpxan3NOD3c=";
            persistencedSha256 = "sha256-AtjM/ml/ngZil8DMYNH+P111ohuk9mWw5t4z7CHjPWw=";
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
        environment.systemPackages = [
          pkgs.wineWowPackages.waylandFull
          # pkgs.winetricks # https://github.com/Winetricks/winetricks/issues/2084#issuecomment-1902843148
        ];
      }
    ];
}

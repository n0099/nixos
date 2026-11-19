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
            # $ version=xxx.xx.xx sh -xc 'nix store prefetch-file https://download.nvidia.com/XFree86/Linux-x86_64/${version}/NVIDIA-Linux-x86_64-$version.run && parallel -k nix-prefetch-github NVIDIA {} --rev $version 2>/dev/null ::: open-gpu-kernel-modules nvidia-{settings,persistenced}'
            version = "620.73.04";
            sha256_64bit = "sha256-tfLi1dqENbMlOTBAFbib9+si/grsjNaQW3puip+bjxs=";
            openSha256 = "sha256-+GPU2bXC/QWZTt0eH3dTvI0bMAta1GCdU2WFI4E4LWE=";
            settingsSha256 = "sha256-Wrv0F7Eo9X/0Xv5DclI9aIe3FcRtbu9okQJuWBjL8es=";
            persistencedSha256 = "sha256-QOndl1q7veD5aB6AfEe0/K2QHR8+ftLsei/aQrUCN3Q=";
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
        environment.systemPackages = [ pkgs.easyeffects ]; # https://github.com/Digitalone1/EasyEffects-Presets https://github.com/jaakkopasanen/AutoEq
      }
      {
        hardware.bluetooth.enable = true;
        programs.kdeconnect.enable = true;
      }
      {
        services.kmscon.hwRender = true;
      }
    ];
}

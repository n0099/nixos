{ lib, ... }:

{
  flake.modules.nixos.zram = lib.mkMerge [
    {
      zramSwap = {
        enable = true;
        memoryPercent = 300;
      };
      boot.kernel.sysctl = {
        # https://unix.stackexchange.com/questions/34034/what-is-the-appropriate-value-of-vm-swappiness-when-using-zram/774112#774112
        # https://news.ycombinator.com/item?id=45686280
        # https://old.reddit.com/r/Fedora/comments/mzun99/new_zram_tuning_benchmarks/
        "vm.page-cluster" = 0;
        "vm.swappiness" = 100;
      };
    }
    {
      # https://news.ycombinator.com/item?id=47500746 https://lobste.rs/s/flmhja/debunking_zswap_zram_myths
      boot.zswap.enable = false;
      n0099.cachyos.mkCachyKernelOverrides.structuredExtraConfig.ZSWAP_DEFAULT_ON = lib.kernel.no; # https://github.com/CachyOS/linux-cachyos/blob/780dd8d6a2e611e3bdca15652845bb635c1fbd7f/linux-cachyos/config#L1234
    }
  ];
}

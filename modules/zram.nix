{ ... }:

{
  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };
  boot.kernel.sysctl = {
    # https://unix.stackexchange.com/questions/34034/what-is-the-appropriate-value-of-vm-swappiness-when-using-zram/774112#774112
    # https://news.ycombinator.com/item?id=45686280
    # https://old.reddit.com/r/Fedora/comments/mzun99/new_zram_tuning_benchmarks/
    "vm.page-cluster" = 0;
    "vm.swappiness" = 150;
  };
}

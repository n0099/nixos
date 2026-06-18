{
  flake.modules.nixos.substituters.nix.settings.substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" # https://mirrors.tuna.tsinghua.edu.cn/help/nix-channels/
  ];
}

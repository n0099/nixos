{ pkgs, inputs, ... }:

{
  imports = [
    ./ide.nix
    ./browser.nix
  ];
  home.packages =
    with pkgs;
    [
      clash-verge-rev
      remmina
      kdePackages.krdc
      kdePackages.krfb
    ]
    ++ (
      let
        # https://nixos.org/manual/nixpkgs/stable/#sec-allow-unfree
        # https://discourse.nixos.org/t/1000-instances-of-nixpkgs/17347
        pkgs-unfree = import inputs.nixpkgs {
          system = "x86_64-linux";
          config.allowUnfreePredicate = pkg: lib.elem (lib.getName pkg) [ "osu-lazer-bin" ];
        };
      in
      [ pkgs-unfree.osu-lazer-bin ]
    );
  programs.ssh = {
    enable = true;
    addKeysToAgent = "ask";
    matchBlocks."*".identityFile = "~/.ssh/id/%r@%h.pem"; # https://askubuntu.com/questions/30788/does-ssh-key-need-to-be-named-id-rsa/423297#423297
  };
}

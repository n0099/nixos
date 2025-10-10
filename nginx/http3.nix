{ lib, pkgs, ... }:

{
  options.services.nginx.virtualHosts = (import ./lib.nix lib).overrideOption { quic = true; };
  config = {
    networking.firewall.allowedUDPPorts = [ 443 ];
    services.nginx = {
      enableQuicBPF = true;
      package = pkgs.nginxQuic;
      additionalModules = [ pkgs.nginxModules.moreheaders ];
      appendHttpConfig = ''
        more_set_headers 'Alt-Svc: h3=":$server_port"; ma=86400'; # https://github.com/NixOS/nixpkgs/pull/449454
      '';
    };
  };
}

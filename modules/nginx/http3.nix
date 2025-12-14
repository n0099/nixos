{
  flake.modules.nixos.nginx-http3 =
    { lib, pkgs, ... }:

    {
      options.services.nginx.virtualHosts = (import ./_lib.nix lib).overrideOption { quic = true; };
      config = {
        networking.firewall.allowedUDPPorts = [ 443 ];
        services.nginx = {
          enableQuicBPF = true;
          additionalModules = [ pkgs.nginxModules.moreheaders ];
          appendHttpConfig = ''
            more_set_headers 'Alt-Svc: h3=":$server_port"; ma=86400'; # https://github.com/NixOS/nixpkgs/pull/449454
            quic_gso on; # https://blog.cloudflare.com/accelerating-udp-packet-transmission-for-quic/#udp-segmentation-offload
          '';
        };
      };
    };
}

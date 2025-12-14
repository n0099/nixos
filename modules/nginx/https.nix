{
  config,
  lib,
  pkgs,
  ...
}:

lib.mkMerge [
  {
    # https://github.com/NixOS/nixpkgs/pull/452972
    security.dhparams.params.nginx = { };
    services.nginx.sslDhparam = config.security.dhparams.params.nginx.path;
  }
  {
    services.nginx = lib.mkMerge [
      {
        # not using https://github.com/NixOS/nixpkgs/blob/20c4598c84a671783f741e02bf05cbfaf4907cff/nixos/modules/services/web-servers/nginx/default.nix#L207-L221
        sslProtocols = "TLSv1.3"; # https://caniuse.com/tls1-3
        appendHttpConfig = ''
          ssl_ecdh_curve secp384r1; # https://community.letsencrypt.org/t/would-it-be-a-good-idea-to-use-x448-only-for-maximum-security/239502

          # https://github.com/igrigorik/istlsfastyet.com/issues/63
          # https://blog.cloudflare.com/optimizing-tls-over-tcp-to-reduce-latency/
          ssl_buffer_size 1400;

          # https://github.com/mozilla/server-side-tls/issues/135#issuecomment-1293210243
          # https://upb-syssec.github.io/blog/2023/session-tickets/
          # https://www.wolfssl.com/tls-session-id-vs-tickets/
          # https://old.reddit.com/r/nginx/comments/11b1hrm/should_ssl_session_cache_be_turned_off_for_tlsv13/
          ssl_session_tickets on;
        '';
      }
      {
        additionalModules = [ pkgs.nginxModules.moreheaders ];
        appendHttpConfig = ''
          # https://wiki.nixos.org/wiki/Nginx#Hardened_setup_with_TLS_and_HSTS_preloading
          map $scheme $hsts_header {
            https "max-age=63072000; includeSubdomains; preload";
          }
          more_set_headers "Strict-Transport-Security $hsts_header";
        '';
      }
    ];
  }
]

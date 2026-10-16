{
  flake.modules.nixos.nginx-log =
    { config, lib, ... }:

    let
      nginxLib = import ./_lib.nix lib;
      logBaseDir = "/var/log/nginx";
      reverseDomainWithSlash =
        # https://en.wikipedia.org/wiki/Reverse_domain_name_notation but replace dot with slash
        domain:
        "${
          domain
          |> lib.splitString "."
          |> lib.reverseList
          |> lib.concatStringsSep "/"
        }";

    in
    {
      options.services.nginx.virtualHosts = nginxLib.overrideOption (
        { name, ... }:

        lib.mkIf (name != "default") {
          extraConfig = ''
            access_log ${logBaseDir}/${reverseDomainWithSlash name}/access.$scheme.log combined;
            error_log ${logBaseDir}/${reverseDomainWithSlash name}/error.log error; # https://trac.nginx.org/nginx/ticket/2307
          '';
        }
      );
      config = lib.mkMerge [
        {
          services.nginx = {
            commonHttpConfig = ''
              # https://blog.neilsabol.site/post/goaccess-apache-httpd-logformat-log-format-combined-common-vhost/
              # https://nginx.org/r/log_format
              log_format combined_with_vhost '$host:$server_port '
                '$remote_addr - $remote_user [$time_local] '
                '"$request" $status $body_bytes_sent '
                '"$http_referer" "$http_user_agent"';
            '';
            virtualHosts.default.extraConfig = ''
              access_log ${logBaseDir}/default/access.$scheme.log combined_with_vhost;
              error_log ${logBaseDir}/default/error.log error;
            '';
          };
        }
        {
          services = {
            nginx.appendHttpConfig = ''
              open_log_file_cache max=512 inactive=1m min_uses=10 valid=2m;
            '';
            logrotate.settings.nginx.files = [
              # https://github.com/NixOS/nixpkgs/blob/20c4598c84a671783f741e02bf05cbfaf4907cff/nixos/modules/services/web-servers/nginx/default.nix#L1662-L1670
              # https://serverfault.com/questions/208006/logrotating-files-in-a-directories-and-its-subdirectories/840384#840384
              "${logBaseDir}/**/*.log"
            ];
          };
          systemd.services.nginx.serviceConfig.LogsDirectory =
            # https://stackoverflow.com/questions/34995385/nginx-create-directory-if-it-doesnt-exist
            (
              config.services.nginx.virtualHosts
              |> lib.attrNames
              |> lib.remove "default"
              |> map reverseDomainWithSlash
            )
            ++ [ "default" ]
            |> map (domain: "${lib.removePrefix "/var/log/" logBaseDir}/${domain}");
        }
      ];
    };
}

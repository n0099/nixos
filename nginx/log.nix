{
  config,
  lib,
  pkgs,
  ...
}:

let
  baseUrls = config.n0099.nginx.baseUrls;
  logBaseDir = "/var/log/nginx";
in
{
  options.n0099.nginx.baseUrls = lib.mkOption {
    type = with lib.types; listOf str;
    default = [ ];
  };
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
          access_log ${logBaseDir}/access.log combined_with_vhost;
        '';
      };
    }
    {
      services.nginx.appendHttpConfig = ''
        map $host$uri $baseUrlLogPath {
          ${lib.concatMapStringsSep "\n" (
            baseUrl: "~^${lib.escapeRegex baseUrl} $scheme/${baseUrl};"
          ) baseUrls}
          default $scheme/$host;
        }
        access_log ${logBaseDir}/$baseUrlLogPath.access.log combined;
        open_log_file_cache max=512 inactive=60s min_uses=10 valid=120s;
        # error_log ${logBaseDir}/$baseUrlLogPath.error.log error; # https://trac.nginx.org/nginx/ticket/2307
      '';
      systemd.services.nginx-mkdir-logs =
        let
          nginxLib = import ./lib.nix lib;
          schemes = [
            # possible values of https://nginx.org/r/$scheme
            "http"
            "https"
          ];
          logDirs =
            (
              {
                scheme = schemes;
                baseUrl = baseUrls;
              }
              |> lib.mapCartesianProduct (
                { scheme, baseUrl }:
                (baseUrl |> lib.splitString "/" |> lib.dropEnd 1) ++ [ scheme ] |> lib.concatStringsSep "/"
              )
            )
            ++ schemes
            |> lib.unique; # https://github.com/NixOS/nixpkgs/pull/355616
        in
        nginxLib.mkServiceRequiredByNginx {
          unitConfig.ConditionPathIsDirectory =
            logDirs |> lib.map (path: "${logBaseDir}/${path}") |> nginxLib.mkServiceConditionAllOfPathsExists;
          serviceConfig.WorkingDirectory = logBaseDir;
          # https://stackoverflow.com/questions/34995385/nginx-create-directory-if-it-doesnt-exist
          script = ''
            ${lib.concatMapStringsSep "\n" (path: "${pkgs.coreutils}/bin/mkdir -p ${path}") logDirs}
            ${pkgs.coreutils}/bin/chown -R nginx: .
          '';
        };
      services.logrotate.settings.nginx.files = [
        # https://github.com/NixOS/nixpkgs/blob/20c4598c84a671783f741e02bf05cbfaf4907cff/nixos/modules/services/web-servers/nginx/default.nix#L1662-L1670
        # https://serverfault.com/questions/208006/logrotating-files-in-a-directories-and-its-subdirectories/840384#840384
        "${logBaseDir}/**/*.log"
      ];
    }
  ];
}

{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.n0099.nginx.baseUrls = lib.mkOption {
    type = with lib.types; listOf str;
    default = [ ];
  };
  config =
    let
      baseUrls = config.n0099.nginx.baseUrls;
      logBaseDir = "/var/log/nginx";
    in
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
            schemes
            ++ lib.unique (
              # https://github.com/NixOS/nixpkgs/pull/355616
              lib.mapCartesianProduct
                (
                  { scheme, baseUrl }:
                  "${scheme}/${lib.concatStringsSep "/" (lib.dropEnd 1 (lib.splitString "/" baseUrl))}"
                )
                {
                  scheme = schemes;
                  baseUrl = baseUrls;
                }
            );
        in
        {
          unitConfig.ConditionPathIsDirectory = nginxLib.mkServiceConditionAllOfPathsExists (
            lib.map (path: "${logBaseDir}/${path}") logDirs
          );
        }
        // (nginxLib.mkServiceRequiredByNginx {
          WorkingDirectory = logBaseDir;
          # https://stackoverflow.com/questions/34995385/nginx-create-directory-if-it-doesnt-exist
          ExecStart = lib.map (path: "${pkgs.coreutils}/bin/mkdir -p ${path}") logDirs;
          ExecStartPost = ''
            ${pkgs.coreutils}/bin/chown -R nginx: .
          '';
        });
      services.logrotate.settings.nginx.files = [
        # https://github.com/NixOS/nixpkgs/blob/20c4598c84a671783f741e02bf05cbfaf4907cff/nixos/modules/services/web-servers/nginx/default.nix#L1662-L1670
        # https://serverfault.com/questions/208006/logrotating-files-in-a-directories-and-its-subdirectories/840384#840384
        "${logBaseDir}/**/*.log"
      ];
    };
}

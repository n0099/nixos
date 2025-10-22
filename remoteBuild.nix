{
  config,
  pkgs,
  lib,
  ...
}:

with { inherit ((import ./toBeFilled/lib.nix) lib) readString; };
lib.mkIf (lib.pathExists ./toBeFilled/remoteBuild) (
  let
    remote = rec {
      host = readString ./toBeFilled/remoteBuild/host;
      port = readString ./toBeFilled/remoteBuild/port;
      maxJobs = lib.toIntBase10 (readString ./toBeFilled/remoteBuild/maxJobs);
      speedFactor = lib.toIntBase10 (readString ./toBeFilled/remoteBuild/speedFactor);
      user = "nix-remote-build";
      privateKey = "/home/n0099/.ssh/id/${user}@${host}:${port}.pem";
    };
  in
  {
    nix = {
      # https://wiki.nixos.org/wiki/Distributed_build#Modify_the_local_machine's_Nix_config_to_know_about_the_remote_machine.
      distributedBuilds = true;
      buildMachines = [
        {
          protocol = "ssh-ng";
          hostName = remote.host;
          inherit (pkgs) system;
          inherit (remote) maxJobs speedFactor;
          supportedFeatures = config.nix.settings.system-features;
        }
      ];
      settings.builders-use-substitutes = true;
    };
    programs.ssh = {
      extraConfig = ''
        # https://wiki.nixos.org/wiki/Distributed_build#Recommended_setup:_multi-user_Nix_local_%E2%80%93%3E_multi-user_Nix_remote
        Host ${remote.host}
          IdentitiesOnly yes
          IdentityFile ${remote.privateKey}
          User ${remote.user}
          Port ${remote.port} # https://github.com/NixOS/nix/issues/724
      '';
      knownHosts.${remote.host}.publicKey = readString ./toBeFilled/remoteBuild/publicKey;
    };
  }
)

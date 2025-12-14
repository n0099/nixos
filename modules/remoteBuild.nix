{
  flake.modules.nixos.remoteBuild =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    with { inherit ((import ./toBeFilled/lib.nix) lib) readString; };
    let
      remote = rec {
        host = ./toBeFilled/remoteBuild/host |> readString;
        port = ./toBeFilled/remoteBuild/port |> readString;
        maxJobs = ./toBeFilled/remoteBuild/maxJobs |> readString |> lib.toIntBase10;
        speedFactor = ./toBeFilled/remoteBuild/speedFactor |> readString |> lib.toIntBase10;
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
        settings = {
          builders-use-substitutes = true;
        }
        // (
          let
            path = ./toBeFilled/remoteBuild/substituterPublicKey;
          in
          lib.mkIf (lib.pathExists path) {
            # https://wiki.nixos.org/wiki/Distributed_build#Using_remote_builders_as_substituters
            trusted-public-keys = [ (readString path) ];
            substituters = [ "ssh://${remote.host}" ];
          }
        );
      };
      programs.ssh = {
        extraConfig = ''
          # https://wiki.nixos.org/wiki/Distributed_build#Recommended_setup:_multi-user_Nix_local_%E2%80%93%3E_multi-user_Nix_remote
          Host ${remote.host}
            IdentitiesOnly yes
            IdentityFile ${remote.privateKey}
            User ${remote.user}
            Port ${remote.port} # https://github.com/NixOS/nix/issues/7044 https://git.lix.systems/lix-project/lix/issues/196
            # https://unix.stackexchange.com/questions/767493/issue-with-ssh-client-alive-interval-in-sshd-config/767515#767515
            # https://serverfault.com/questions/1162826/how-to-ensure-that-ssh-drops-the-connection-after-8-hours-of-no-typing/1162840#1162840
            ChannelTimeout *=1m
        '';
        knownHosts.${remote.host}.publicKey = ./toBeFilled/remoteBuild/publicKey |> readString;
      };
    }
    |> lib.mkIf (lib.pathExists ./toBeFilled/remoteBuild);
}

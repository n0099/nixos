{
  flake.modules = {
    nixos.ssh = {
      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        }
        // {
          PermitRootLogin = "no";
          ClientAliveInterval = 15;
        };
      };
      # https://github.com/nix-community/srvos/blob/3fb70232a9fe901d943d0340ab99fa36abb62418/shared/common/well-known-hosts.nix#L7
      # https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
      programs.ssh.knownHosts."github.com".publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    };
    homeManager.ssh = {
      services.ssh-agent.enable = true;
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings."*" = {
          addKeysToAgent = "1h"; # https://man.archlinux.org/man/sshd_config.5#TIME_FORMATS
          serverAliveInterval = 15;
          identityFile = "~/.ssh/id/%r@%h:%p.pem"; # https://askubuntu.com/questions/30788/does-ssh-key-need-to-be-named-id-rsa/423297#423297
        };
      };
    };
  };
}

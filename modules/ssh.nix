{
  flake.modules = {
    nixos.ssh.services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      }
      // {
        ClientAliveInterval = 15;
      };
    };
    homeManager.ssh = {
      services.ssh-agent.enable = true;
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks."*" = {
          addKeysToAgent = "1h"; # https://man.archlinux.org/man/sshd_config.5#TIME_FORMATS
          serverAliveInterval = 15;
          identityFile = "~/.ssh/id/%r@%h:%p.pem"; # https://askubuntu.com/questions/30788/does-ssh-key-need-to-be-named-id-rsa/423297#423297
        };
      };
    };
  };
}

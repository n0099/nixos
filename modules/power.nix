{
  flake.modules = {
    nixos.power =
      { config, ... }:

      {
        powerManagement = {
          cpufreq.min = 5000000; # 5GHz
          resumeCommands = config.systemd.services.cpufreq.serviceConfig.ExecStart;
        };
      };
    homeManager.power = {
      programs.plasma.powerdevil.AC = {
        autoSuspend.action = "nothing";
        powerProfile = "performance";
      };
    };
  };
}

let
  host = "localhost";
  port = 1080;
  proxy = "${host}:${builtins.toString port}";
in
{
  flake.modules = {
    nixos.proxy =
      { config, lib, ... }:

      lib.mkMerge [
        {
          networking.proxy = {
            default = "socks5h://${proxy}";
            noProxy = "127.0.0.1,localhost";
          };
        }
        {
          systemd.services.sanoid.environment = config.networking.proxy.envVars;
        }
      ];
    homeManager.proxy =
      { lib, pkgs, ... }:

      lib.mkMerge [
        {
          programs.librewolf.policies.Proxy = {
            Mode = "manual";
            SOCKSProxy = proxy;
          };
        }
        {
          programs.ssh.settings = lib.genAttrs [ "github.com" "gist.github.com" ] (_: {
            proxyCommand =
              # https://stackoverflow.com/questions/1728934/accessing-a-git-repository-via-ssh-behind-a-firewall/8255371#8255371
              "${lib.getExe pkgs.socat} - PROXY:${host}:%h:%p,proxyport=${builtins.toString port}";
          });
        }
        {
          home.packages = [
            (pkgs.clash-verge-rev.overrideAttrs (
              prev:
              let
                unwrapped = prev.passthru.unwrapped.overrideAttrs (prev: {
                  # https://github.com/NixOS/nixpkgs/pull/539637
                  patches = (prev.patches or [ ]) ++ [
                    (pkgs.writeText "prevent-writing-mimeapps" ''
                      diff --git a/src-tauri/src/utils/init.rs b/src-tauri/src/utils/init.rs
                      index 43b61c8f..5094667a 100644
                      --- a/src-tauri/src/utils/init.rs
                      +++ b/src-tauri/src/utils/init.rs
                      @@ -384,24 +384,6 @@ pub fn init_scheme() -> Result<()> {
                       }
                       #[cfg(target_os = "linux")]
                       pub fn init_scheme() -> Result<()> {
                      -    const DESKTOP_FILE: &str = "clash-verge.desktop";
                      -
                      -    for scheme in DEEP_LINK_SCHEMES {
                      -        let handler = format!("x-scheme-handler/{scheme}");
                      -        let output = std::process::Command::new("xdg-mime")
                      -            .arg("default")
                      -            .arg(DESKTOP_FILE)
                      -            .arg(&handler)
                      -            .output()?;
                      -        if !output.status.success() {
                      -            return Err(anyhow::anyhow!(
                      -                "failed to set {handler}, {}",
                      -                String::from_utf8_lossy(&output.stderr)
                      -            ));
                      -        }
                      -    }
                      -
                      -    crate::utils::linux::mime::ensure_mimeapps_entries(DESKTOP_FILE, DEEP_LINK_SCHEMES)?;
                           Ok(())
                       }
                       #[cfg(target_os = "macos")]
                    '')
                  ];
                });
              in
              {
                installPhase =
                  lib.replaceString prev.passthru.unwrapped.outPath unwrapped.outPath
                    prev.installPhase;
                passthru = (prev.passthru or { }) // {
                  inherit unwrapped;
                };
              }
            ))
          ];
        }
      ];
  };
}

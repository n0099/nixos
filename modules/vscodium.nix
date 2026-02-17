{
  flake.modules = {
    nixos.vscode =
      { inputs, ... }:

      {
        nixpkgs.overlays = [ inputs.nix-vscode-extensions.overlays.default ];
      };
    homeManager.vscode =
      {
        config,
        lib,
        pkgs,
        ...
      }:

      let
        extensions = lib.recursiveUpdate pkgs.vscode-marketplace-release pkgs.open-vsx-release; # https://github.com/nix-community/nix-vscode-extensions/blob/c19ba2ee9cc749fc62eb2f4b39bc7b12b2d6a0bb/README.md#extension-attrsets
        flatSettings = # https://discourse.nixos.org/t/flatten-nested-set-to-name-value-pairs-named-after-the-old-path/59713
          set:
          let
            recurse =
              path:
              lib.concatMapAttrs (
                name: value:
                if builtins.isAttrs value then
                  recurse (path ++ [ name ]) value
                else
                  { ${builtins.concatStringsSep "." (path ++ [ name ])} = value; }
              );
          in
          recurse [ ] set;
        overrideExtensionExecutableConfig =
          configKey: executablePkg: drv:
          drv.overrideAttrs (
            final: prev: {
              nativeBuildInputs =
                with pkgs;
                prev.nativeBuildInputs or [ ]
                ++ [
                  jq
                  moreutils
                ];
              postInstall = prev.postInstall or "" + ''
                cd "$out/$installPrefix"
                jq -e '.contributes.configuration.properties."${configKey}".default = "${lib.getExe executablePkg}"' package.json | sponge package.json
              '';
            }
          );
      in
      {
        programs.vscode = {
          enable = true;
          package = pkgs.vscodium;
          profiles = {
            default = lib.mkMerge [
              {
                userSettings =
                  flatSettings {
                    editor = {
                      fontLigatures = true;
                      bracketPairColorization.enabled = true;
                    };
                    diffEditor = {
                      ignoreTrimWhitespace = false;
                      experimental.showMoves = true;
                      hideUnchangedRegions.enabled = true;
                    };
                    files.autoGuessEncoding = true;
                  }
                  // {
                    "files.associations"."*.json5" = "jsonc";
                  };
                extensions = with extensions; [
                  zxh404.vscode-proto3
                  ahmadalli.vscode-nginx-conf
                  ms-vscode.hexeditor
                  mechatroner.rainbow-csv

                  editorconfig.editorconfig
                  mikestead.dotenv
                  (
                    mkhl.direnv # https://github.com/NixOS/nixpkgs/pull/491239
                    |> overrideExtensionExecutableConfig "direnv.path.executable" pkgs.direnv
                  )
                  jnoortheen.nix-ide

                  qcz.text-power-tools

                  davidanson.vscode-markdownlint
                  shd101wyy.markdown-preview-enhanced
                  pkgs.vscode-marketplace-release.bierner.markdown-preview-github-styles # https://github.com/mjbvz/vscode-github-markdown-preview-style/issues/59#issuecomment-1499414723

                  (
                    mads-hartmann.bash-ide-vscode # https://github.com/NixOS/nixpkgs/pull/491237
                    |> overrideExtensionExecutableConfig "bashIde.shellcheckPath" pkgs.shellcheck
                    |> overrideExtensionExecutableConfig "bashIde.shfmt.path" pkgs.shfmt
                  )

                  github.vscode-github-actions
                ];
              }
              {
                extensions = [ extensions.redhat.vscode-yaml ];
                userSettings."redhat.telemetry.enabled" = false;
              }
              {
                extensions = with extensions; [
                  docker.docker
                  # ms-azuretools.vscode-containers
                ];
                userSettings."docker.lsp.telemetry" = "off";
              }
              {
                extensions = [ extensions.eamodio.gitlens ];
                userSettings = flatSettings {
                  gitlens = {
                    telemetry.enabled = false;
                    launchpad.indicator.enabled = false;
                  };
                };
              }
              {
                extensions = [ extensions.atommaterial.a-file-icon-vscode ];
                userSettings."workbench.iconTheme" = "a-file-icon-vscode";
              }
            ];
            fe =
              let
                default = config.programs.vscode.profiles.default;
              in
              {
                userSettings = default.userSettings;
                extensions =
                  with extensions;
                  default.extensions
                  ++ [
                    vue.volar
                    dbaeumer.vscode-eslint
                    stylelint.vscode-stylelint
                    webben.browserslist
                    kimuson.ts-type-expand
                    antfu.goto-alias
                    arcanis.vscode-zipfs
                  ];
              };
          };
        };
      };
  };
}

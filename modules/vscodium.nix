{
  flake.modules = {
    nixos.vscode =
      { inputs, ... }:

      {
        nixpkgs.overlays = [ inputs.nix4vscode.overlays.default ];
      };
    homeManager.vscode =
      {
        config,
        lib,
        pkgs,
        ...
      }:

      let
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
        vscodeVersion = config.programs.vscode.package.version;
        forVscodeVersion = pkgs.nix4vscode.forVscodeVersion vscodeVersion;
        forOpenVsxVersion = pkgs.nix4vscode.forOpenVsxVersion vscodeVersion;
        forOpenVsxExtVersion =
          decorators:
          decorators |> lib.attrNames |> pkgs.nix4vscode.forOpenVsxExtVersion decorators vscodeVersion;
        decorateExtensionExecutableConfig = configs: {
          nativeBuildInputs = with pkgs; [
            jq
            moreutils
          ];
          postInstall = ''
            cd "$out/$installPrefix"
            jq -e '
              ${lib.concatMapAttrsStringSep "| \n" (configKey: executablePkg: ''
                .contributes.configuration.properties."${configKey}".default = "${lib.getExe executablePkg}"
              '') configs}
            ' package.json | sponge package.json
          '';
        };
      in
      {
        programs.vscode = {
          enable = true;
          package = pkgs.vscodium;
          profiles =
            {
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
                      scm.inputFontFamily = "editor";
                      files = {
                        autoGuessEncoding = true;
                        trimTrailingWhitespace = true;
                      };
                    }
                    // {
                      "files.associations"."*.json5" = "jsonc";
                    };
                  extensions =
                    forVscodeVersion [ "ahmadalli.vscode-nginx-conf" ]
                    ++ forOpenVsxVersion [
                      "zxh404.vscode-proto3"
                      "ms-vscode.hexeditor"
                      "mechatroner.rainbow-csv"

                      "editorconfig.editorconfig"
                      "mikestead.dotenv"
                      "jnoortheen.nix-ide"

                      "qcz.text-power-tools"

                      "davidanson.vscode-markdownlint"
                      "shd101wyy.markdown-preview-enhanced"

                      "github.vscode-github-actions"
                    ]
                    ++ forVscodeVersion [
                      "bierner.markdown-preview-github-styles" # https://github.com/mjbvz/vscode-github-markdown-preview-style/issues/59#issuecomment-1499414723
                    ]
                    ++ forOpenVsxExtVersion {
                      "mkhl.direnv" = decorateExtensionExecutableConfig {
                        # https://github.com/NixOS/nixpkgs/pull/491239
                        "direnv.path.executable" = pkgs.direnv;
                      };
                      "mads-hartmann.bash-ide-vscode" = decorateExtensionExecutableConfig {
                        # https://github.com/NixOS/nixpkgs/pull/491237
                        "bashIde.shellcheckPath" = pkgs.shellcheck;
                        "bashIde.shfmt.path" = pkgs.shfmt;
                      };
                    };
                }
                {
                  extensions = forOpenVsxVersion [ "redhat.vscode-yaml" ];
                  userSettings."redhat.telemetry.enabled" = false;
                }
                {
                  extensions = forOpenVsxVersion [
                    "docker.docker"
                    # "ms-azuretools.vscode-containers"
                  ];
                  userSettings."docker.lsp.telemetry" = "off";
                }
                {
                  extensions = forOpenVsxVersion [ "eamodio.gitlens" ];
                  userSettings = flatSettings {
                    gitlens = {
                      ai.enabled = false;
                      telemetry.enabled = false;
                      advanced.skipOnboarding = true;
                      plusFeatures.enabled = false;
                      launchpad.indicator.enabled = false;
                    };
                  };
                }
                {
                  extensions = forVscodeVersion [ "atommaterial.a-file-icon-vscode" ];
                  userSettings."workbench.iconTheme" = "a-file-icon-vscode";
                }
              ];
              Frontend =
                let
                  default = config.programs.vscode.profiles.default;
                in
                lib.mkMerge [
                  {
                    userSettings = default.userSettings;
                    extensions =
                      default.extensions
                      ++ forOpenVsxVersion [
                        "vue.volar.3.0.7" # https://github.com/vuejs/language-tools/issues/5941
                        "dbaeumer.vscode-eslint"
                        "stylelint.vscode-stylelint"
                        "arcanis.vscode-zipfs"
                      ]
                      ++ forVscodeVersion [
                        "kimuson.ts-type-expand"
                        "webben.browserslist"
                      ];
                  }
                  {
                    extensions = forOpenVsxVersion [ "antfu.goto-alias" ];
                    userSettings."editor.gotoLocation.multipleDefinitions" = "gotoAndPeek";
                  }
                ];
            }
            |> lib.concatMapAttrs (
              name: profile:
              let
                name' = if name == "default" then "Default" else name; # https://github.com/nix-community/home-manager/blob/0d782ee42c86b196acff08acfbf41bb7d13eed5b/modules/programs/vscode/default.nix#L85
              in
              {
                ${name} = profile;
                "${name'} Inline Diff" = lib.mkMerge [
                  profile
                  {
                    userSettings."diffEditor.renderSideBySide" = false;
                  }
                ];
              }
            );
        };
      };
  };
}

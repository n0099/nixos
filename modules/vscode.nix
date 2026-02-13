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
      in
      {
        programs.vscode = {
          enable = true;
          package = pkgs.vscodium;
          profiles = {
            default.extensions = with extensions; [
              zxh404.vscode-proto3
              ahmadalli.vscode-nginx-conf
              ms-vscode.hexeditor
              mechatroner.rainbow-csv

              editorconfig.editorconfig
              mikestead.dotenv
              mkhl.direnv
              jnoortheen.nix-ide

              eamodio.gitlens
              qcz.text-power-tools
              atommaterial.a-file-icon-vscode

              davidanson.vscode-markdownlint
              shd101wyy.markdown-preview-enhanced
              pkgs.vscode-marketplace-release.bierner.markdown-preview-github-styles # https://github.com/mjbvz/vscode-github-markdown-preview-style/issues/59#issuecomment-1499414723

              timonwong.shellcheck
              mads-hartmann.bash-ide-vscode

              redhat.vscode-yaml
              github.vscode-github-actions

              docker.docker
              ms-azuretools.vscode-containers
            ];
            fe.extensions =
              with extensions;
              config.programs.vscode.profiles.default.extensions
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
}

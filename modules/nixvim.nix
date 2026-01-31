{
  flake.modules.nixos.nixvim =
    { pkgs, ... }:

    {
      programs.nixvim.extraPlugins = [
        (pkgs.writeTextDir "queries/nix/injections.scm" /* scheme */ ''
          ; https://github.com/calops/hmts.nvim/pull/30
          (binding
            attrpath: (_) @_path (#hmts-path? @_path "programs" "(firefox|floorp|librewolf|thunderbird)" "profiles" ".*" "userC(hrome|ontent)")
            expression: (_ (string_fragment) @injection.content)
            (#set! injection.language "css")
            (#set! injection.combined)
          )

          ; https://github.com/calops/hmts.nvim/pull/33
          (binding
            attrpath: (_) @_path (#hmts-path? @_path "fonts" "fontconfig" "localConf")
            expression: (_ (string_fragment) @injection.content)
            (#set! injection.language "xml")
            (#set! injection.combined)
          )
          (binding
            attrpath: (_) @_path (#hmts-path? @_path "fonts" "fontconfig" "configFile" ".*" "text")
            expression: (_ (string_fragment) @injection.content)
            (#set! injection.language "xml")
            (#set! injection.combined)
          )
        '')
      ];
    };
}

{
  flake.modules.nixos.font =
    { pkgs, lib, ... }:

    {
      fonts = lib.mkMerge [
        {
          packages = with pkgs; [ last-resort ];
          fontconfig = {
            enable = true;
            localConf = lib.mkBefore /* xml */ ''
              <?xml version="1.0"?>
              <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
              <fontconfig>
            '';
          };
        }
        {
          # test with ⠿ https://codepoints.net/U+283F
          # $ FC_DEBUG=4 pango-view --font monospace -t ⠿ | grep family:
          # $ fc-match -s :family=monospace:charset=283F | head
          fontconfig.localConf = ''
            <match target="font">
              <!-- https://discuss.kde.org/t/konsole-renders-btop-characters-not-properly/12502 -->
              <!-- https://stackoverflow.com/questions/47501411/how-to-set-font-per-unicode-range-codepoint-in-fontconfig/47614324#47614324 -->
              <!-- https://github.com/cjbassi/ytop/issues/79#issuecomment-676070893 -->
              <test name="family" compare="eq">
                <string>FreeMono</string>
              </test>
              <edit name="charset" mode="assign">
                <minus>
                  <name>charset</name>
                  <charset>
                    <range>
                      <!-- https://codepoints.net/braille_patterns -->
                      <int>0x2800</int>
                      <int>0x28FF</int>
                    </range>
                  </charset>
                </minus>
              </edit>
            </match>
          '';
        }
        {
          packages = with pkgs; [
            # source-sans
            source-han-sans
            # source-han-sans-vf-otf
            # source-serif
            source-han-serif
            # source-han-serif-vf-otf
            # source-code-pro
            source-han-mono
          ];
          # test with 门关复
          # $ FC_DEBUG=4 pango-view --font monospace -t 门关复 | grep family:
          # $ fc-match -s :family=monospace:charset=95E8:charset=5173:charset=590D | head
          fontconfig.localConf = ''
            <!-- https://gist.github.com/akiirui/b3f36e8bdf9a9f5636a98113960bc7f4 -->
            <!-- https://japanese.stackexchange.com/questions/86411/why-are-%E5%85%B3-and-%E5%A4%8D-half-width-in-japanese -->
            <match target="pattern">
              <test name="family">
                <string>serif</string>
              </test>
              <edit name="family" mode="append" binding="strong">
                <string>Source Han Serif SC</string>
              </edit>
            </match>
            <match target="pattern">
              <test name="family">
                <string>sans-serif</string>
              </test>
              <edit name="family" mode="append" binding="strong">
                <string>Source Han Sans SC</string>
              </edit>
            </match>
            <match target="pattern">
              <test name="family">
                <string>monospace</string>
              </test>
              <edit name="family" mode="append" binding="strong">
                <string>Source Han Mono SC</string>
              </edit>
            </match>
          '';
        }
        {
          fontconfig.localConf = lib.mkAfter "</fontconfig>";
        }
      ];
    };
}

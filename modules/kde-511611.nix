{
  flake.modules.nixos.kde-511611.nixpkgs.overlays = [
    # https://github.com/NixOS/nixpkgs/pull/510034
    # https://bugs.kde.org/show_bug.cgi?id=511611
    (final: prev: {
      kdePackages = prev.kdePackages.overrideScope (
        _: prev: {
          kwin = prev.kwin.overrideAttrs (
            _: prev: {
              patches = prev.patches ++ [
                (final.fetchpatch2 {
                  url = "https://invent.kde.org/plasma/kwin/-/merge_requests/8716.patch";
                  hash = "sha256-0ank79YBspBzYvXT59XZ/eV62sdoo3AjRT9tXdCjHEc=";
                })
              ];
            }
          );
        }
      );
    })
  ];
}

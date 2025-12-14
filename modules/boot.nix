{
  flake.modules.nixos.boot =
    { lib, ... }:

    {
      boot.loader = {
        systemd-boot.enable = false |> lib.mkForce;
        efi.efiSysMountPoint = "/efi";
        grub = {
          enable = true;
          device = "nodev";
          efiSupport = true;
          enableCryptodisk = true;
          extraGrubInstallArgs = [
            # https://wiki.archlinux.org/title/GRUB#LUKS2
            # https://github.com/dmoulding/grub-luks2-install/blob/525d757950685888455359618f3fe489c118ca81/grub-luks2-install#L329-L370
            # https://wiki.archlinux.org/title/GRUB#Shim-lock
            ''
              --modules=
                luks2
                gcry_sha512
                pbkdf2
            ''
          ];
        };
      };
    };
}

{ lib, ... }:

{
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    grub = {
      enable = true;
      efiSupport = true;
      enableCryptodisk = true;
      device = "nodev";
      extraGrubInstallArgs = [
        # https://wiki.archlinux.org/title/GRUB#LUKS2
        # https://github.com/dmoulding/grub-luks2-install/blob/525d757950685888455359618f3fe489c118ca81/grub-luks2-install#L329-L370
        # https://wiki.archlinux.org/title/GRUB#Shim-lock
        ''
          --modules=
            cryptodisk
            luks2
            gcry_rijndael
            gcry_sha512
            pbkdf2
        ''
      ];
    };
    efi.efiSysMountPoint = "/efi";
  };
}

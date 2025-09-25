{ lib, ... }:

{
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    grub = {
      enable = true;
      efiSupport = true;
      enableCryptodisk = true;
      device = "nodev";
      extraPerEntryConfig = ''
        # https://wiki.archlinux.org/title/GRUB#LUKS2
        # https://github.com/dmoulding/grub-luks2-install/blob/525d757950685888455359618f3fe489c118ca81/grub-luks2-install#L329-L370
        insmod cryptodisk
        insmod luks2
        insmod gcry_rijndael
        insmod gcry_sha512
        insmod pbkdf2
      '';
    };
    efi.efiSysMountPoint = "/efi";
  };
}

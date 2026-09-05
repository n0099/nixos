{
  flake.modules.nixos.misc =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    lib.mkMerge [
      {
        n0099.cachyos = {
          enable = true;
          variant = "bmq-lto";
          mkCachyKernelOverrides.prePatch =
            let
              patch = pkgs.fetchpatch {
                url = "https://github.com/CachyOS/linux/commit/d286c785c4c385e10eb1c8c440a6a0c4496a73ad.patch";
                hash = "sha256-cjV+MyFgzFQwu4mTxd0qUGV3uY2q9Gj/fo5HqRaUi7Y=";
              };
            in
            "patch -Rp1 < ${patch}";
        };
      }
      {
        boot.zfs.package = pkgs.zfs_2_4;
        nixpkgs.overlays = [
          (_: prev: {
            kernelPackagesExtensions = prev.kernelPackagesExtensions ++ [
              # https://github.com/NixOS/nixpkgs/blob/5dfba6236110080a54247d6460bc2ff5dda939cc/pkgs/top-level/linux-kernels.nix#L668
              (
                _: prev:
                let
                  pkgName = config.boot.zfs.package.kernelModuleAttribute; # https://github.com/NixOS/nixpkgs/blob/fd1462031fdee08f65fd0b4c6b64e22239a77870/nixos/modules/tasks/filesystems/zfs.nix#L22
                in
                {
                  ${pkgName} = prev.${pkgName}.overrideAttrs (prev: {
                    patches = prev.patches ++ [
                      (pkgs.writeText "https://github.com/openzfs/zfs/issues/11140#issuecomment-5498519538" ''
                        diff --git a/module/os/linux/zfs/zpl_inode.c b/module/os/linux/zfs/zpl_inode.c
                        index 3492f4a..37caaab 100644
                        --- a/module/os/linux/zfs/zpl_inode.c
                        +++ b/module/os/linux/zfs/zpl_inode.c
                        @@ -279,6 +279,7 @@ zpl_mknod(struct inode *dir, struct dentry *dentry, umode_t mode,
                         	return (error);
                         }

                        +#if 0
                         static int
                         #ifdef HAVE_TMPFILE_IDMAP
                         zpl_tmpfile(struct mnt_idmap *userns, struct inode *dir,
                        @@ -347,6 +348,7 @@ zpl_tmpfile(struct inode *dir, struct dentry *dentry, umode_t mode)

                         	return (error);
                         }
                        +#endif

                         static int
                         zpl_unlink(struct inode *dir, struct dentry *dentry)
                        @@ -851,7 +853,6 @@ const struct inode_operations zpl_dir_inode_operations = {
                         	.rmdir		= zpl_rmdir,
                         	.mknod		= zpl_mknod,
                         	.rename		= zpl_rename,
                        -	.tmpfile	= zpl_tmpfile,
                         	.setattr	= zpl_setattr,
                         	.getattr	= zpl_getattr,
                         	.listxattr	= zpl_xattr_list,
                      '')
                    ];
                  });
                }
              )
            ];
          })
        ];
        networking.hostId = "ec1ca6eb";
        n0099.sanoid.enable = true;
        services.sanoid.datasets =
          lib.genAttrs
            (map (dataset: "rpool/ENC/${dataset}") [
              "WIN11"
              "NIX-BUILD"
              "NIX-BUILD-LOG"
            ])
            (_: {
              autosnap = false;
            });
      }
      {
        hardware.rasdaemon.enable = true;
      }
      {
        environment.systemPackages = [ pkgs.pcm ];
        boot.kernelModules = [ "msr" ];
      }
      {
        systemd.coredump.settings.Coredump = {
          # https://www.freedesktop.org/software/systemd/man/247/systemd-coredump.html#Disabling%20coredump%20processing
          Storage = "none";
          ProcessSizeMax = 0;
        };
      }
      {
        environment.systemPackages = [ pkgs.devenv ];
      }
    ];
}

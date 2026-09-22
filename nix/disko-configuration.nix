{
  disko.devices = {
    disk = {
      sata = {
        type = "disk";
        device = "/dev/disk/by-id/redacted";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "storage";
              };
            };
          };
        };
      };
    };

    zpool = {
      storage = {
        type = "zpool";
        options.ashift = "12";
        rootFsOptions = {
          "com.sun:auto-snapshot" = "false";
          compression = "zstd";
          atime = "off";
          mountpoint = "none";
        };

        datasets = {
          "data" = {
            type = "zfs_fs";
            mountpoint = "/mnt/sata";
          };
        };
      };
    };
  };
}

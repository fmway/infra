{
  disko.devices.disk = {
    vda = {
      type = "disk";
      name = "main-{{uuid}}";
      device = "{{mainDisk}}";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            priority = 1;
            name  = "BOOT";
            size   = "1G";
            type  = "EF00";
            content = {
              type       = "filesystem";
              format     = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type       = "filesystem";
              format     = "xfs";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}

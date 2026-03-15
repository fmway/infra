# ---
# schema = "xfs"
# [placeholders]
# mainDisk = "/dev/disk/by-id/scsi-360011e8e533c4c22952770566bd22299" 
# ---
# This file was automatically generated!
# CHANGING this configuration requires wiping and reinstalling the machine
{
  disko.devices.disk = {
    vda = {
      type = "disk";
      name = "main-5e197739aa504df09436686f922d5c1c";
      device = "/dev/disk/by-id/scsi-360011e8e533c4c22952770566bd22299";
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

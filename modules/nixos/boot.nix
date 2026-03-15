{ lib, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  boot.kernelParams = [
    "console=tty1"
    "console=ttyS0,115200n8"
  ];

  boot.loader.systemd-boot = {
    enable = true;
    memtest86.enable = lib.mkDefault true;
    configurationLimit = 6;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  boot.tmp.cleanOnBoot = lib.mkDefault true;
  boot.tmp.useTmpfs = lib.mkDefault false;

  boot.kernel.sysctl  = {
    # Swap configuration
    "vm.swappiness" = 150;
    "vm.watermark_boost_factor" = 5000;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
  };

  swapDevices = [ { device = "/var/lib/swapfile"; size   = 2048; } ];
}

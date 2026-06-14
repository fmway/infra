{ lib, inputs, ... }:
{
  fclan.extras = let
    myLib = import ../../_lib { inherit inputs lib; };
  in {
    nixos = { config, ... }: let mem = myLib.get_memory config.hardware.facter.report; in {
      # limit vps for the small vps :(
      services.journald.extraConfig = lib.mkIf ((myLib.cast mem).to_g < 1.6) ''
        SystemMaxUse=40M
        SystemMaxFileSize=10M
      '';
    };
  };
}

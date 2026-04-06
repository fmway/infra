{ lib, ... }:
{ config, ... }: let
  getIpController = (
    builtins.elemAt (
      builtins.elemAt (builtins.attrValues (
        lib.filterAttrs (_: x: x.peer.controller or false) config.clanConfig.exports)
      ) 0
    ).peer.hosts 0
  ).plain;
in {
  imports = [
    { config._module.args.theConfig = config; }
  ];
  networking.hosts."${getIpController}" = [ "dyndns.clan" ];
}

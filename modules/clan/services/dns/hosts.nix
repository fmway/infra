{ lib, ... }:
{
  fclan.dns.nixos = { config, ... }: let
    getIpController = (
      builtins.elemAt (
        builtins.elemAt (builtins.attrValues (
          lib.filterAttrs (_: x: x.peer.controller or false) config.clanConfig.exports)
        ) 0
      ).peer.hosts 0
    ).plain;
  in {
    networking.hosts."${getIpController}" = [ "dyndns.clan" ];
  };
}

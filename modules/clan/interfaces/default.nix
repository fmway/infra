{ lib, ... }:
{
  den.clan.exportInterfaces.peer.options.controller = lib.mkEnableOption "is controller or not";
}

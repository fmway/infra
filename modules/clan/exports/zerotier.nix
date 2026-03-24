{ lib, ... }:
{
  options.devices = lib.mkOption {
    type = with lib.types; attrsOf (listOf str);
    default = {};
  };
}

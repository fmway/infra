{ lib, ... }:
{
  options = {
    domains = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options.alts = lib.mkOption {
          type = with lib.types; listOf str;
          default = [];
        };
        options.port = lib.mkOption {
          type = with lib.types; nullOr port;
          default = null;
        };
      });
      default = {};
    };
  };
}

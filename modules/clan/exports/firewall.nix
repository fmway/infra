{ lib, ... }:
{
  /*
    not really necessary, just to expose open ports to clan exports, maybe will be used in the future
  */
  options = {
    openPorts = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          ports = lib.mkOption {
            description = "List ports that will open";
            type = with lib.types; listOf (either port ranges-port);
            default = [];
          };
          interfaces = lib.mkOption {
            description = "Specific interfaces, null means all interfaces";
            type = with lib.types; nullOr (listOf str);
            default = null;
          };
          protocol = lib.mkOption {
            description = "Specific protocol";
            type = lib.types.enum [ "tcp" "udp" "udp-tcp" "tcp-udp" ];
            default = "tcp-udp";
          };
        };
      });
      description = "...";
      default = [];
    };
  };
}

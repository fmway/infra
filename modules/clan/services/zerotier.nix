{ lib, ... }:
{
  fclan.zerotier = {
    clan.manifest.name = lib.mkForce "@extra/zerotier";

    controller = { instance, ... }: {
      # TODO:
      peer = { settings, ... }: builtins.mapAttrs (_: v: {
        hosts = map (plain: { inherit plain; }) v;
      }) settings.extraDevices;
      interface = { lib, config, ... }:
      {
        options = {
          extraDevices = lib.mkOption {
            type = with lib.types; attrsOf (listOf str);
            apply = value: let
              deviceList = builtins.attrNames value;
              _check = builtins.any (x: let r = instance ? peer.machines.${x}; in lib.throwIf r "Duplicated extraDevices `${x}` with clan machines" r) deviceList;
            in if _check then value else value;
            default = {};
            description = "Devices that not managed by clan";
          };
          dns.enable = lib.mkEnableOption "enable local dns";
          dns.serverName = lib.mkOption {
            type = lib.types.str;
          };
        };

        config.allowedIps = builtins.concatLists (lib.attrValues config.extraDevices);
      };

      nixos = { settings, pkgs, config, machine, ... }: let
        ip = config.clan.core.vars.generators."zerotier-ip-${machine.name}-${instance.name}".files.ip.value;
      in {
        config = lib.mkMerge [
          {
            networking.hosts."${ip}" = [ "dyndns.clan" ]; # should be in dyndns
          }
          (lib.mkIf settings.dns.enable {
            clan.core.zerotier.networks.${instance.name}.settings.dns = {
              domain = settings.dns.serverName;
              servers = [ ip ];
            };
          })
        ];
      };
    };
  };
}

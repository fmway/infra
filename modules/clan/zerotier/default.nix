{ internal, lib, inputs, ... }:
lib.clan.extendService inputs.clan-core.clan.modules.zerotier
({ exports, config, ... }: let
  filter-zerotier = lib.clan.selectExports ({ machineName, serviceName, roleName, ... }:
    machineName != "" &&
    roleName == "peer" &&
    serviceName == manifest.name
  ) exports;

  manifest = config.manifest;
in {
  _class = "clan.service";
  manifest.name = "@extra/zerotier";
  # manifest.exports.inputs = [ "networking" ];
  manifest.exports.out = [ "zerotier" ];

  roles.controller = {
    interface = { lib, config, ... }:
    {
      # FIXME: disallow duplicated name with instances
      options.extraDevices = lib.mkOption {
        type = with lib.types; attrsOf (listOf str);
        default = {};
        description = "Devices that not managed by clan";
      };

      config.allowedIps = lib.flatten (lib.attrValues config.extraDevices);
    };

    perInstance = { mkExports, settings, ... }:
    {
      exports = mkExports {
        zerotier.devices = lib.mapAttrs' (k: v: let
          info = lib.clan.parseScope k;
        in {
          name = info.machineName;
          value = [ (builtins.head v.peer.hosts).plain ];
        }) filter-zerotier // settings.extraDevices;
      };
    };
  };

  roles.peer = {
    perInstance = { machine, instanceName, ... }:
    {
      nixosModule = { config, ... }: let
        domain = config.clan.core.settings.domain;
        zerotier = (builtins.head (
          builtins.attrValues (
            lib.clan.selectExports ({ serviceName, roleName, ... } @ x:
              roleName == "controller" &&
              serviceName == manifest.name &&
              x.instanceName == instanceName
            ) exports
          )
        )).zerotier;
      in {
        imports = [
          ({ ... }: {
            # loopback
            networking = rec {
              hosts = {
                "127.0.0.1" = [ "${machine.name}.zt" "${machine.name}.${domain}" ];
                "::1" = hosts."127.0.0.1";
              };
            };
          })
        ];

        # connection between machines over zerotier, per-machine can connect to other with domain <machine>.zt and <machine>.<domain>
        networking.hosts =
          builtins.mapAttrs (_: list: lib.flatten (map (x: [ "${x.name}.zt" "${x.name}.${domain}" ]) list)) (
            builtins.groupBy (x: x.value) (
              builtins.concatMap
                (name: map (value: { inherit name value; }) zerotier.devices.${name})
                (builtins.attrNames zerotier.devices)
            )
          );
      };
    };
  };
})

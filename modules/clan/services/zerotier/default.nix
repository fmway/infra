{ lib, inputs, ... }:
{
  fclan.zerotier = { clanLib, ... }:
  {
    clan = { config, ... }: let
      # we assume instance and controller machine is only one
      manifest = config.manifest;
      instanceName = builtins.elemAt (builtins.attrNames config.instances) 0;
      instance = config.instances.${instanceName};
      machines = instance.roles.controller.machines;
      firstMachineName = builtins.elemAt (builtins.attrNames machines) 0;
      firstMachine = machines.${firstMachineName};
      extraDevices = firstMachine.finalSettings.config.extraDevices;
      peerMachineList = builtins.attrNames instance.roles.peer.machines;
    in {
      _class = "clan.service";
      imports = [
        inputs.clan-core.clan.modules.zerotier
      ];
      manifest.name = lib.mkForce "@extra/zerotier";

      exports = lib.mkMerge (map (machineName: lib.mkIf (extraDevices != {}) {
        ${clanLib.buildScopeKey {
          inherit instanceName machineName;
          serviceName = manifest.name;
          roleName = "peer";
        }}.peer.hosts = map (plain: { inherit plain; }) extraDevices.${machineName};
      }) (builtins.attrNames extraDevices));

      roles.controller = {
        interface = { lib, config, ... }:
        {
          options.extraDevices = lib.mkOption {
            type = with lib.types; attrsOf (listOf str);
            apply = value: let
              deviceList = builtins.attrNames value;
              _check = builtins.any (x: let r = builtins.elem x peerMachineList; in lib.throwIf r "Duplicated extraDevices `${x}` with clan machines" r) deviceList;
            in if _check then value else value;
            default = {};
            description = "Devices that not managed by clan";
          };

          config.allowedIps = lib.flatten (lib.attrValues config.extraDevices);
        };
      };

      roles.peer = {
        perInstance = { mkExports, machine, ... }:
        {
          exports = mkExports {
            peer.controller = machine.name == firstMachineName;
          };
        };
      };
    };
  };
}

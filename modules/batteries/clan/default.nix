{ den, lib, config, inputs, ... }: let
  inherit (den.lib) policy;
  extra-lib = {
    myLib = import ../../_lib { inherit lib inputs; };
    clanLib = inputs.clan-core.lib;
  };

  clanModule.den.schema.host = { host, ... }:
    {
      options = {
        clan.enable = lib.mkEnableOption "enable clan";
        clan.machineName = lib.mkOption {
          type = lib.types.str;
          default = host.name;
        };
      };
    };
in {
  den.classes.clan.description = "clan services";
  den.schema.clan-machine = {
    isEntity = true;
    includes = [
      (policy.mkPolicy "machine-arg" ({ clan-machine, ... }: policy.resolve {
        machine = clan-machine;
        machineName = clan-machine.name;
        inherit (extra-lib) myLib clanLib;
      }))
    ];
  };
  den.schema.clan-instance = {
    isEntity = true;
    includes = [
      (policy.mkPolicy "instance-arg" ({ clan-instance, ... }: policy.resolve {
        instance = clan-instance;
        instanceName = clan-instance.name;
        inherit (extra-lib) myLib clanLib;
      }))
    ];
  };

  den.schema.host.includes = [
    den.policies.clan-to-nixos
  ];
  den.policies.clan-to-nixos =
    { host, ... }:
      (den.lib.policy.provide {
        class = "nixos";
        module.imports = [
          (config.flake.clan.outputs.moduleForMachine.${host.clan.machineName} or {})
        ];
      });

  imports = [
    clanModule
  ];
}

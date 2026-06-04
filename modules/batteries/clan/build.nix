{ den, lib, inputs, debug ? false, ... }: let
  inherit (inputs.clan-core.lib) clan;
  inherit (den.lib) aspects policy resolveEntity;
  instances = den.clan.inventory.instances; 
  inherit (inputs.clan-core.inputs.nix-select.lib) select;

  genModule = entity: let
    clan-service = aspects.resolve "clan" entity.resolved;
    emptyClan  = clan-service.imports == [];
    nullModuleName = isNull entity.module.name;
    nullModuleInput= isNull entity.module.input;
    selfModule = hasAspect && nullModuleName;
    hasAspect  = !isNull entity.aspect;
    metaModule =
      if nullModuleName && nullModuleInput && !hasAspect then {
        name = entity.name;
      } else if selfModule && emptyClan then {
        name = "importer";
      } else if selfModule then {
        name = entity.name;
        input = "self";
      } else entity.module;
  in {
    metaModule = { input = null; } // metaModule;
  } // lib.optionalAttrs (selfModule && !emptyClan) {
    module = builtins.head (builtins.concatMap (x: x.imports) clan-service.imports);
  };

  services = select "*.instances.*.roles.*.machines.*.finalSettings.config" b.config._services.allServices;
  aspectExtraModules = { host, ... }:
  {
    name = "clan/extraModules";
    ${host.class}.imports = builtins.concatMap
      (serviceName: builtins.concatMap
        (instanceName: builtins.concatMap
          (roleName: let
            included =
              services.${serviceName}.${instanceName}.${roleName} ? ${host.clan.machineName} &&
              !isNull den.clan.inventory.instances.${instanceName}.aspect;
            settings = services.${serviceName}.${instanceName}.${roleName}.${host.clan.machineName};
            entity = resolveEntity "clan-instance" { inherit settings host; role = roleName; };
            resolved = entity // {
              includes = entity.includes ++ [ den.clan.inventory.instances.${instanceName}.aspect ];
            };
            module = aspects.resolve host.class resolved;
          in lib.optional included module)
        (builtins.attrNames services.${serviceName}.${instanceName}))
      (builtins.attrNames services.${serviceName}))
    (builtins.attrNames services);
  };

  r = builtins.foldl' (a: c: let
    mod = genModule instances.${c};
  in lib.recursiveUpdate a ({
    instances.${c} = {
      roles = instances.${c}.roles;
      module = mod.metaModule;
    };
  } // lib.optionalAttrs (mod ? module) {
    modules.${c} = mod.module;
  })) {} (builtins.attrNames instances);

  fleet = {
    modules = r.modules or {};
    self = inputs.self;
    directory = den.clan.directory;
    meta = den.clan.meta;
    exportInterfaces = den.clan.exportInterfaces;
    inventory = {
      instances = r.instances;
      machines = builtins.mapAttrs (_: v: { inherit (v) deploy machineClass tags; }) den.clan.inventory.machines;
    };
    machines = builtins.mapAttrs (_: v: aspects.resolve "nixos" v.resolved) den.clan.inventory.machines;
  };

  b = clan fleet;
in {
  den.schema.host.includes = [
    aspectExtraModules
  ];
  flake = {
    clan = b.config;
    clanInternals = b.config.clanInternals;
  } // lib.optionalAttrs debug {
    _clan = b;
    fleet = fleet;
    genModule = genModule;
  };
}

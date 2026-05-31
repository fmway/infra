{ den, lib, inputs, ... }: let
  inherit (inputs.clan-core.lib) clan;
  inherit (den.lib) aspects;
  instances = den.clan.inventory.instances; 

  genModule = entity: let
    clan-service = aspects.resolve "clan" entity.resolved;
    nixos = aspects.resolve "nixos" entity.resolved;
    emptyNixos = nixos.imports == [];
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
    inherit metaModule;
  } // lib.optionalAttrs (hasAspect && !emptyNixos) {
    extraModules = [ nixos ];
  } // lib.optionalAttrs (selfModule && !emptyClan) {
    module = builtins.head (builtins.concatMap (x: x.imports) clan-service.imports);
  };

  r = builtins.foldl' (a: c: let
    mod = genModule instances.${c};
    extraMod.default = instances.${c}.roles.default or {} // {
      extraModules = instances.${c}.roles.default.extraModules or [] ++ mod.extraModules;
    };
  in lib.recursiveUpdate a ({
    instances.${c} = {
      roles = instances.${c}.roles // lib.optionalAttrs (mod ? extraModules) extraMod;
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
  flake = {
    clan = b.config;
    clanInternals = b.config.clanInternals;
    _clan = b;
    _fleet = fleet;
    _genModule = genModule;
  };
}

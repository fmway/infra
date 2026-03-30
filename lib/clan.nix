{ internal, super, inputs, lib, ... }: let
  list-inputs = builtins.attrNames inputs;

  # self and clan-core as priority, the rest sorted by alphanumeric
  weight = name:
    if name == "self" then 0
    else if name == "clan-core" then 1
    else 2;

  sortedInputs = builtins.sort (a: b: let
    wa = weight a; wb = weight b;
  in if wa != wb then wa < wb else a < b) list-inputs;

  chooseInputByName = name:
    builtins.foldl' (a: input:
      if !isNull a || inputs.${input}.clan.modules.${name} or "" == "" then
        a
      else
        input
    ) null sortedInputs;

  overridePerInstance = old: new: { settings, machine, instanceName, mkExports, ... } @ a: let
    args = a // { inherit settings machine instanceName mkExports; };
    newPerInstance'= new.perInstance or {};
    oldPerInstance'= old.perInstance or {};
    oldPerInstance = if builtins.isFunction oldPerInstance' then oldPerInstance' args else oldPerInstance';
    newPerInstance = if builtins.isFunction newPerInstance' then newPerInstance' args else newPerInstance';
  in lib.optionalAttrs (oldPerInstance?exports || newPerInstance?exports) {
    exports = lib.mkMerge [(oldPerInstance.exports or {}) (newPerInstance.exports or {})];
  } // lib.optionalAttrs (oldPerInstance?nixosModule || newPerInstance?nixosModule) {
    nixosModule = { ... }: {
      imports =
        lib.optional (oldPerInstance?nixosModule) oldPerInstance.nixosModule
      ++lib.optional (newPerInstance?nixosModule) newPerInstance.nixosModule
      ;
    };
  } // lib.optionalAttrs (oldPerInstance?darwinModule || newPerInstance?darwinModule) {
    darwinModule = { ... }: {
      imports =
        lib.optional (oldPerInstance?darwinModule) oldPerInstance.darwinModule
      ++lib.optional (newPerInstance?darwinModule) newPerInstance.darwinModule
      ;
    };
  };
in super.clan // {
  autoChooseModule = builtins.mapAttrs (x: value: let
      name = value.module.name or x;
    in value // lib.optionalAttrs (!value?module.input) {
      module = value.module or {} // {
        input = chooseInputByName name;
      };
    });

  extendService = path: new: let
    old-module = import path;
    fixOldModule = if builtins.isFunction old-module then old-module else _: old-module;
    fixNewModule = if builtins.isFunction new then new else _: new;
  in { directory, clanLib, exports, config, ... } @ a: let
    input = a // { inherit directory clanLib config exports; };
    oldAttrs = fixOldModule input;
    newAttrs = fixNewModule input;
  in lib.optionalAttrs (newAttrs?exports || oldAttrs?exports) {
    exports = lib.mkMerge [ (oldAttrs.exports or {}) (newAttrs.exports or {}) ];
  } // lib.optionalAttrs (newAttrs?perInstance || oldAttrs?perInstance) {
    perInstance = overridePerInstance oldAttrs newAttrs;
  } // {
    _class = "clan.service";
    manifest = lib.mkMerge [ (oldAttrs.manifest or {}) (newAttrs.manifest or {}) ];

    roles = newAttrs.roles or {} // builtins.mapAttrs (k: oldRole: let newRole = newAttrs.roles.${k} or {}; in {
      description = newRole.description or oldRole.description or "";
      interface = { ... }: {
        imports =
          lib.optional (oldRole?interface) oldRole.interface
        ++lib.optional (newRole?interface) newRole.interface
        ;
      };

      perInstance = overridePerInstance oldRole newRole;
    }) oldAttrs.roles;
  };

  mapFilterExports = fn: filter: exports:
    lib.mapAttrs' (k: let info = lib.clan.parseScope k; in fn (info // { _orig = k; })) (lib.filterAttrs filter exports);

  mapIntoListsFilterExports = fn: filter: exports: let
    filtered = lib.filterAttrs filter exports;
  in map (k: let info = lib.clan.parseScope k; in fn (info // { _orig = k; }) filtered.${k}) (builtins.attrNames filtered);
}

{ lib, inputs, ... }:
{
  get_memory = report:
    if isNull report || report.hardware.memory or [] == [] then null else
    builtins.foldl' builtins.add 0
    (builtins.concatMap (x:
      map
        (x: x.range)
        (builtins.filter (x: x.type == "phys_mem") x.resources)
    ) report.hardware.memory);

  cast = val: let
    val' = if builtins.isString val && !isNull (builtins.match "^[0-9]+(.[0-9]+)?$" val) then builtins.fromJSON val else val;
    t    = builtins.typeOf val';
    _num = lib.throwIfNot (builtins.elem t [ "int" "float" ]) "(cast): Only supported number" val';
    r = {
      from_k = 1.0 * _num * 1000;
      from_m = r.from_k * 1000;
      from_g = r.from_m * 1000;

      to_k   = 1.0 * _num / 1000;
      to_m   = r.to_k / 1000;
      to_g   = r.to_m / 1000;

      str    = let
        r = builtins.toJSON val';
        m = builtins.match "^([0-9]+)[.][0]+$" r;
      in if builtins.isString val' then val' else if isNull m then r else builtins.head m;
    };
  in r;

  subnet = ip: let
    matched = builtins.match "^([^:]+:[^:]+:[^:]+:[^:]+):.*$" ip;
  in assert !isNull matched; builtins.head matched + "::/64";

  clan = let
    extractInfo = fn: x: fn (inputs.clan-core.lib.parseScope x // { __toString = _: x; });
  in {
    mapFilterExports = fn: filter: exports:
      lib.mapAttrs' (extractInfo fn) (lib.filterAttrs (extractInfo filter) exports);

    mapIntoListsFilterExports = fn: filter: exports: let
      filtered = lib.filterAttrs (extractInfo filter) exports;
    in map (k: extractInfo fn k filtered.${k}) (builtins.attrNames filtered);
  };
  types = import ./types.nix { inherit lib; };
}

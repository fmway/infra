{ lib, ... }:
{
  isDomainInclude = inc: domain:
    !isNull (builtins.match "^([*][.])?(.+[.])?${lib.fmway.fixedInMatch inc}$" domain);
  get_memory = report:
    if isNull report || report.hardware.memory or [] == [] then null else
    builtins.foldl' builtins.add 0
    (builtins.concatMap (x:
      map
        (x: x.range)
        (builtins.filter (x: x.type == "phys_mem") x.resources)
    ) report.hardware.memory);

  cast = val: let
    t    = builtins.typeOf val;
    _num = lib.throwIfNot (builtins.elem t [ "int" "float" ]) "Only supported number" val;
    r = {
      from_k = 1.0 * _num * 1000;
      from_m = r.from_k * 1000;
      from_g = r.from_m * 1000;

      to_k   = 1.0 * _num / 1000;
      to_m   = r.to_k / 1000;
      to_g   = r.to_m / 1000;

      str    = if t == "bool" then if val then "true" else "false" else toString val;
    };
  in r;
}

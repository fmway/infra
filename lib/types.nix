{ lib, super, ... }: let
  parseRangesToObj = value: let
    parts = builtins.match "([0-9]+)-([0-9]+)" value;
    start = lib.toInt (builtins.elemAt parts 0);
    end = lib.toInt (builtins.elemAt parts 1);
  in if isNull parts then null else { inherit start end; };
in super.types // {
  ranges-port = lib.mkOptionType {
    name = "ranges-port";
    description = "A string representing a port range in the format '<start>-<end>', where start and end are u16 ports and end > start";
    check = value:
      let
        p = if builtins.isString value then parseRangesToObj value else p;
      in
        (
          (builtins.isString value && p != null) ||
          (builtins.isAttrs value && value ? start && value ? end)
        ) &&
        lib.types.ints.u16.check p.start &&
        lib.types.ints.u16.check p.end &&
        p.end > p.start;
    merge = loc: defs: let value = (builtins.head defs).value; in
      if builtins.isAttrs value then
        value
      else parseRangesToObj value;
  };
}

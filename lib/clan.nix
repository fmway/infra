{ internal, super, inputs, ... }: let
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
in super.clan // {
  autoChooseModule = builtins.mapAttrs (x: value: let
      name = value.module.name or x;
    in value // {
      module = value.module or {} // {
        input = chooseInputByName name;
      };
    });
}

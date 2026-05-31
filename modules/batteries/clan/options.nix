{ lib, inputs, den, ... }:
{
  options.den.clan = {
    directory = lib.mkOption {
      type = lib.types.path;
      default = inputs.self.outPath;
    };
    meta = lib.mkOption {
      description = ''
        Global information about the clan.
      '';
      type = lib.types.submoduleWith {
        modules = [
          "${inputs.clan-core}/modules/inventoryClass/meta.nix"
        ];
      };
      default = { };
    };

    exportInterfaces = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = {};
    };

    inventory.instances = lib.mkOption {
      default = {};
      type = lib.types.attrsOf (lib.types.submodule ({ name, config, ... }: {
        freeformType = lib.types.attrsOf lib.types.anything;
        imports = [ den.schema.clan-instance ];
        config._module.args.instance = config;
        config._module.args.instanceName = name;
        options = {
          module.name = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          module.input = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          name = lib.mkOption {
            type = lib.types.str;
            readOnly = true;
            default = name;
          };
          aspect = lib.mkOption {
            type = lib.types.raw;
            default = den.aspects.${name} or null;
          };
          roles = lib.mkOption {
            default = { };
            type = lib.types.attrsOf (
              lib.types.submodule {
                imports = [
                  (import "${inputs.clan-core}/modules/inventoryClass/role.nix" { } { inherit lib; clanLib = inputs.clan-core.lib // {
                    types = inputs.clan-core.lib.types // {
                      uniqueDeferredSerializableModule = lib.types.toml;
                    };
                  }; })
                ];
              }
            );
          };
        };
      }));
    };

    inventory.machines = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ config, name, ... }: {
        freeformType = lib.types.attrsOf lib.types.anything;
        imports = [ den.schema.clan-machine ];
        config._module.args.machine = config;
        config._module.args.machineName = name;
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            readOnly = true;
            default = name;
          };
          aspect = lib.mkOption {
            type = lib.types.raw;
            default = den.aspects.${name};
          };
          tags = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            apply = lib.unique;
            default = [];
          };
          machineClass = lib.mkOption {
            type = lib.types.enum [ "nixos" "darwin" ];
            default = "nixos";
          };
          deploy.targetHost = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          deploy.buildHost = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
        };
      }));
      default = {};
    };
  };
}

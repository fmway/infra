{ exports, lib, ... }:
{
  _class = "clan.service";
  manifest.name = "coredns";
  manifest.description = "Clan-internal DNS and service exposure";
  manifest.categories = [ "Network" ];
  manifest.exports.inputs = [ "peer" ];
  manifest.readme = builtins.readFile ./README.md;

  roles.default = {
    description = "";
    interface = { lib, ... }:
    {
      options.alts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "alt domains";
      };
    };

    perInstance = { roles, machine, settings, ... }:
    {
      nixosModule = { config, ... }: let
        domains = [config.clan.core.settings.domain] ++ settings.alts;
        devices = lib.mapAttrs' (k: v: let info = lib.clan.parseScope k; in {
          name = info.machineName;
          value = map (x: x.plain) v.peer.hosts;
        }) (lib.filterAttrs (k: v: v.peer.hosts or [] != []) exports);
      in {
        imports = [
          ({ ... }: {
            # loopback
            networking = rec {
              hosts = {
                "127.0.0.1" = map (tld: "${machine.name}.${tld}") domains;
                "::1" = hosts."127.0.0.1";
              };
            };
          })
        ];

        # connection between machines over zerotier, per-machine can connect to other with domain <machine>.zt and <machine>.<domain>
        networking.hosts = lib.mkMerge [
          (builtins.mapAttrs (_: list: lib.flatten (map (x: map (tld: "${x.name}.${tld}") domains) list)) (
            builtins.groupBy (x: x.value) (
              builtins.concatMap
                (name: map (value: { inherit name value; }) devices.${name})
                (builtins.attrNames devices)
            )
          ))
        ];
      };
    };
  };
}

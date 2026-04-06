{ exports, lib, config, meta, ... }: let
  instanceName = builtins.elemAt (builtins.attrNames config.instances) 0;
  instance = config.instances.${instanceName};
  serverMachineName = builtins.elemAt (builtins.attrNames instance.roles.server.machines) 0;
  serverMachine = instance.roles.server.machines.${serverMachineName};
  serverSettings = serverMachine.finalSettings.config;
  clients = builtins.mapAttrs (_: v: v.finalSettings.config) instance.roles.default.machines;

  devices = lib.clan.mapFilterExports ({ machineName, ... }: v: {
    name = machineName;
    value = builtins.filter builtins.isString (
      map (x:
        x.plain or
        (lib.clan.getPublicValue (x.var or {} // { default = null; }))
      ) v.peer.hosts
    );
  }) (k: v: v.peer.hosts or [] != []) exports;

  privateDomains = [meta.domain] ++ serverSettings.alt.privates;

  # map all peers to private domains
  peerMaps = builtins.mapAttrs (_: list: lib.flatten (map (x: map (tld: "${x.name}.${tld}") privateDomains) list)) (
    builtins.groupBy (x: x.value) (
      builtins.concatMap
        (name: map (value: { inherit name value; }) devices.${name})
        (builtins.attrNames devices)
    )
  );

  ip = builtins.elemAt (lib.flatten (
    lib.clan.mapIntoListsFilterExports (_: v:
      map (x: x.plain) v.peer.hosts
    ) (_: x: x.peer.hosts or [] != [] && x.peer.controller or false) exports
  )) 0;

in {
  _class = "clan.service";
  manifest.name = "dns";
  manifest.description = "Clan-internal DNS and service exposure";
  manifest.categories = [ "Network" ];
  manifest.exports.inputs = [ "peer" ];
  manifest.exports.out = [ "dns" ];
  manifest.readme = builtins.readFile ./README.md;

  roles.server = {
    description = "";
    interface = { lib, ... }:
    {
      options = {
        # TODO
        # serverType = lib.mkOption {
        #   type = lib.types.enum [ "caddy" ];
        #   default = "caddy";
        # };
        # implementation = lib.mkOption {
        #   type = lib.types.enum [ "adguardhome" ];
        #   default = "adguardhome";
        # };

        dnsPort = lib.mkOption {
          type = lib.types.port;
          default = 53;
        };

        # extra private tlds
        alt.privates = lib.mkOption {
          type = with lib.types; listOf str;
          default = [];
        };

        # TODO: combine with dyndns ootb
        # alt.publics = lib.mkOption {
        #   type = lib.types.listOf (lib.types.submodule {
        #     options = {
        #       domains = lib.mkOption {
        #         type = with lib.types; listOf str;
        #         default = [];
        #       };
        #       provider = lib.mkOption {
        #         type = lib.types.enum [ "cloudflare" ];
        #         default = "cloudflare";
        #       };
        #     };
        #   });
        #   default = [];
        # };

        hostname = lib.mkOption {
          description = "hostname for dns server";
          type = with lib.types; nullOr str;
          default = null;
        };
      };
    };

    perInstance = { mkExports, settings, instanceName, machine, ... }:
    {
      exports = mkExports {
        dns.domains."${settings.hostname}".alts = [ "*.${settings.hostname}" ];
      };

      nixosModule = { lib, ... }:
      {
        imports = [
          (lib.modules.importApply ./adguardhome.nix { inherit clients settings instanceName machine mkExports serverSettings exports lib peerMaps ip; })
        ];
      };
    };
  };

  roles.default = {
    description = "";
    perInstance = { machine, ... }:
    {
      nixosModule = { lib, ... }:
      {
        # connection between machines over zerotier, per-machine can connect to other with domain <machine>.zt and <machine>.<domain>
        networking.hosts = peerMaps;
        # networking.nameservers = lib.mkBefore [
        #   "${ip}#${serverSettings.hostname}"
        # ];
        # services.resolved.settings.Resolve.FallbackDNS = [
        #   "9.9.9.9"
        # ];
      };
    };
  };
}

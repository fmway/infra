{ lib, inputs, config, ... }: let
  namespace = "fclan";
in {
  imports = [
    (inputs.den.namespace namespace true)
  ];
  clan = {

    # Useful when i just imported the modules without the full flake
    directory = builtins.toPath ../..;

    meta.name = namespace;
    meta.domain = "clan.fmway.me";
    namespace = config.clan.meta.name;

    inventory.machines = {
      /*
        # TAGS
        - `online` -> the devices expected as a server
        - `local` -> local machines, the opposite of `online` (laptop/pc/etc)
        - `network-controller` -> the global server to routing all devices (zerotier, dns, etc)
      */
      opc1.tags = [ "network-controller" "online" ];
      t480.tags = [ "local" ];
    };

    inventory.instances = {
      zerotier = {
        module.name = "zerotier";
        roles.controller = {
          settings = {
            extraDevices = {
              xiao = ["fd15:a6cd:10e3:f0e0:4099:937e:ac9:5c2c"];
            };
            dns.enable = true;
            dns.serverName = "dns.fmway.me";
          };
          tags.network-controller = { };
        };
        roles.peer.tags.all = { };
        roles.moon.machines.opc1.settings.stableEndpoints = [ "161.118.224.161" ];
      };

      dns = {
        roles.server.machines.opc1 = {};
        roles.server.settings = {
          hostname = "dns.fmway.me";
          dnsPort = 5335;
          alt.privates = [ "clan" "zt" ];

          # TODO
          # alt.publics = [
          #   { domains = [ "fmway.me" ]; provider = "cloudflare"; }
          # ];
        };
        roles.default.tags.all = { };
      };

      dyndns = {
        module.name = "dyndns";
        roles.default.machines.opc1 = {};
        roles.default.settings = {
          server = {
            enable = true;
            domain = "dyndns.clan";
            acmeEmail = "fm18lv@gmail.com";
          };
          period = 15;
          settings = {
            "fmway" = {
              provider = "cloudflare";
              domain = "fmway.me";
              secret_field_name = "token";

              extraSettings = {
                host = "dns,*.dns,git,vault"; # TODO: autodetect by exports (dns + dyndns)
                ttl = 1;
                zone_identifier = "ec3141584414b7a28efcbbc0bc913e75";
              };
            };
          };
        };
      };

      vaultwarden.roles.default.machines.opc1 = {};
      extras.roles.default.tags.online = {};

      nix-token = {
        roles.default.tags.all = {};
        roles.default.settings.share = true;
      };

      clan-cache = {
        module.name = "trusted-nix-caches";
        roles.default.tags.online = { };
      };
    };
  };

  den.schema.clan-machine.includes = [
    ({ clan-machine, ... }: lib.optionalAttrs (builtins.elem "local" clan-machine.tags) {
      nixos.clan.core.deployment.requireExplicitUpdate = true;
      nixos.clan.core.settings.state-version.enable = false;
    })
  ];

  # fclan.t480 = {};
  # fclan.opc1 = {};
}

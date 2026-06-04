{ den, lib, inputs, ... }:
{
  den.clan = {

    # Useful when i just imported the modules without the full flake
    directory = builtins.toPath ../..;

    meta.name = "fclan";
    meta.domain = "clan.fmway.me";

    inventory.machines = {
      opc1.tags = [ "network-controller" "online" ];
      t480.tags = [ "local" ];
    };

    # TODO: avoid extraModules, inject via aspects with param { tags } for conditional
    inventory.instances = {
      zerotier = {
        roles.controller = {
          settings.extraDevices = {
            xiao = ["fd15:a6cd:10e3:f0e0:4099:937e:ac9:5c2c"];
          };
          tags.network-controller = { };
          extraModules = [
            ({ config, pkgs, ... }: let
              networkId = config.clan.core.vars.generators."zerotier-network-zerotier".files.network-id.value;
              dns = builtins.toJSON { domain = "dns.fmway.me"; servers = [ config.clan.core.vars.generators.zerotier-ip-zerotier.files.ip.value ]; };
            in {
              config.systemd.services.zerotierone.serviceConfig.ExecStartPre = lib.mkAfter [
                "+${pkgs.writeShellScript "custom-dns" ''
                  TARGET="/var/lib/zerotier-one/controller.d/network/${networkId}.json"
                  OLD="$(realpath "$TARGET")"
                  unlink "$TARGET"
                  ${lib.getExe pkgs.jq} '.dns = ${dns}' < "$OLD" > "$TARGET"
                ''}"
              ];
            })
          ];
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

      extras.roles.default.tags.online = {};
      firewall.roles.default.tags.nixos = {};
      vaultwarden.roles.default.machines.opc1 = {};

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
}

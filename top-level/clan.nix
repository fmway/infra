{ config, lib, inputs, ... }:
{
  # use `lib.fix` instead of `rec` keyword for recursive attrs. we can't use `config.clan` bcz clan has a special merge in inventory settings
  clan = lib.fix (s: {
    self = inputs.self;
    specialArgs = config._module.specialArgs;
    meta.name = "fclan";
    meta.domain = "clan.fmway.me";

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

    inventory.instances = lib.clan.autoChooseModule {
      # internet = { };
      zerotier = {
        roles.controller = {
          settings.extraDevices = {
            xiao = ["fd00:ee1e:cd28:dad3:9599:937e:ac9:5c2c"];
          };
          tags.network-controller = { };
          extraModules = [
            ({ config, ... }: {
              config.clan.core.networking.zerotier.settings.dns = {
                domain = "dns.fmway.me";
                servers = [
                  config.clan.core.vars.generators.zerotier.files.zerotier-ip.value
                ];
              };
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
        roles.default.extraModules = [
          (lib.modules.importApply ./extra/dns.nix { inherit lib; })
        ];
      };

      # TODO: dns + dyndns
      dyndns = {
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
        roles.default.extraModules = [
          (lib.modules.importApply ./extra/dyndns.nix s)
        ];
      };

      sshd = {
        roles.server.tags.all = { };
        roles.server.settings = {
          authorizedKeys = {
            fmway = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDD7g5NRKn0VP/TGMO7RsNRZVlOcOFRHZg2flAkrEIABkbYS93ERGphDk5f18SPECiElUr9a9OdkkjYsvcfDsJ976BBQFqwAAAcfk/V8eJoZCyS/IR7IDLTI0kxAb+kr8OO4+jztuKY4qmBMPli0TYK6WoFqdBouegbgVE/6tUgp+Cif1BDHNjgWgPqE4Iz/gtWI5j+5SnBfZDIoMB+dqBgOx42AWZvlCJegRds6Rqk/2TmsIyX+/DvCllQjPC1VdKWkOcNQCDBt8WkBlo8gBzrtwiPp4kdFSgxWo3iuBKyAAixlfaUI87KvoDqQqQEmxfnTQkXHpyNOFnZp5nXxgXwO3W8Dzi4Kt9Wnyb//F6umH6CKor57iDxbXxjtvp0Klu4c/Ioj8bpJzbMYSlmpSY57b6Jsbq7FUEebo7GTCTvSSfeybZtw409r3Vk8hxqk7uVlZQOh5r+Or0KXae+rBU6DPGVeAcnBzg3B2V/mZn9QKELcXBSQb2+M9NJdDx5TP0= namaku1801@gmail.com";
          };
          hostKeys.rsa.enable = true;
        };
      };

      "user@server" = {
        module.name = "users";
        roles.default.tags.online = {};
        roles.default.settings = {
          user = "user";
          openssh.authorizedKeys.keys = builtins.attrValues (s.inventory.instances.sshd.roles.server.settings.authorizedKeys or {});
          groups = [ "users" "networkmanager" "wheel" ];
          share = true;
        };
      };

      "root@server" = {
        module.name = "users";
        roles.default.tags.online = {};
        roles.default.settings = {
          user = "root";
          share = true;
        };
      };

      importer = {
        roles.default.tags.online = {};
        roles.default.extraModules = [
          inputs.self.nixosModules.all
          ({ config, ... }: let mem = lib.get_memory config.hardware.facter.report; in {
            # limit vps for the small vps :(
            services.journald.extraConfig = lib.mkIf ((lib.cast mem).to_g < 1.6) ''
              SystemMaxUse=40M
              SystemMaxFileSize=10M
            '';
          })
        ];
      };

      /*
        collects firewall openPorts exports, then insert into 
      */
      firewall = {
        module.name = "importer";
        roles.default.tags.nixos = {};
        roles.default.extraModules = [
          ./extra/firewall.nix
        ];
      };

      vaultwarden = {
        module.name = "importer";
        roles.default.machines.opc1 = {};
        # roles.default.machines.t480 = {};
        roles.default.extraModules = [
          (lib.modules.importApply ./extra/vaultwarden.nix s)
        ];
      };

      nix-token = {
        roles.default.tags.all = {};
        roles.default.settings.share = true;
      };

      clan-cache = {
        module.name = "trusted-nix-caches";
        roles.default.tags.online = { };
      };
    };

    machines = builtins.mapAttrs (k: v:
      # all local machines need to explicit update
      lib.optionalAttrs (builtins.elem "local" v.tags) {
        clan.core.deployment.requireExplicitUpdate = true;
      }
    ) s.inventory.machines;
  });

  imports = [
    inputs.clan-core.flakeModules.default
    # TODO: autoRenamed from flake.clanModules to clan.modules;
    ({ config, ... }: {
      clan.modules = lib.filterAttrs (k: _: !builtins.any (x: k == x) [ "all" "within" "without" ]) config.flake.clanModules or {};
    })
    ({ lib, ... }: {
      clan.exportInterfaces.peer.options.controller = lib.mkEnableOption "is controller or not";
    })
    # export types related
    ({ lib, ... }: {
      config = lib.mkIf (lib.pathIsDirectory ../modules/clan/exports) {
        clan.exportInterfaces = lib.mapAttrs' (file: _: {
          name = lib.removeSuffix ".nix" file;
          value = ../modules/clan/exports + "/${file}";
        }) (builtins.readDir ../modules/clan/exports);
      };
    })
  ];
}

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
        };
        roles.peer.tags.all = { };
        roles.moon.machines.opc1.settings.stableEndpoints = [ "161.118.224.161" ];
      };

      dns.roles.default = {
        tags.all = { };
        settings.alts = [ "clan" "zt" ];
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
          ({ lib, config, ... }: let
            filterOnlyHasFirewall = builtins.attrValues (lib.filterAttrs (k: v: let
              info = lib.clan.parseScope k;
              machineName = config.clan.core.settings.machine.name;
            in info.machineName == machineName && v ? firewall) config.clanConfig.exports);

            openPorts = lib.flatten (map (x: x.firewall.openPorts) filterOnlyHasFirewall);

            allowPorts = map ({ ports, interfaces, protocol }: let
              value = lib.foldl' (a: c: let
                t = if c ? start && c ? end then "Range" else "";
                p = { udp = -1; tcp-udp = 0; udp-tcp = 0; tcp = 1; }.${protocol};
              in a // {
                "allowedUDPPort${t}s" = a."allowedUDPPort${t}s" ++ lib.optional (p <= 0) c;
                "allowedTCPPort${t}s" = a."allowedTCPPort${t}s" ++ lib.optional (p >= 0) c;
              }) { allowedUDPPorts = []; allowedTCPPorts = []; allowedUDPPortRanges = []; allowedTCPPortRanges = []; } ports;
            in if isNull interfaces then
              value
            else {
              interfaces = builtins.listToAttrs (map (name: {
                inherit name value;
              }) interfaces);
            }) openPorts;

          in {
            config = lib.mkIf (openPorts != []) {
              networking.firewall = lib.mkMerge allowPorts;
            };
          })
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

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
      opc1 = {
        tags = [ "network-controller" "online" ];
        deploy.targetHost = "161.118.224.161";
      };

      t480 = {
        tags = [ "local" ];
        deploy.targetHost = "localhost";
      };
    };

    inventory.instances = lib.clan.autoChooseModule {
      # internet = {};
      zerotier = {
        roles.controller.tags.network-controller = { };
        roles.peer.tags.all = { };
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

      "user@nixos" = {
        module.name = "users";
        roles.default.tags.online = {};
        roles.default.settings = {
          user = "user";
          openssh.authorizedKeys = builtins.attrValues (s.inventory.instances.sshd.roles.server.settings.authorizedKeys or {});
          groups = [ "users" "networkmanager" "wheel" ];
          share = true;
        };
      };

      "root@nixos" = {
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
        ];
      };

      clan-cache = {
        module.name = "trusted-nix-caches";
        roles.default.tags.online = { };
      };
    };

    machines = builtins.mapAttrs (k: v:
      # all local machines need to explicit update
      lib.optionalAttrs (builtins.elem "local" v.tags) {
        clan.deployment.requireExplicitUpdate = true;
      }
    ) s.inventory.machines;
  });

  imports = [
    inputs.clan-core.flakeModules.default
    # TODO: autoRenamed from flake.clanModules to clan.modules;
    ({ config, ... }: {
      clan.modules = lib.filterAttrs (k: _: !builtins.any (x: k == x) [ "all" "within" "without" ]) config.flake.clanModules or {};
    })
  ];
}

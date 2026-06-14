{ config, ... }:
{
  clan.inventory.instances = {
    sshd = {
      module.name = "sshd";
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
        openssh.authorizedKeys.keys = builtins.attrValues (config.clan.inventory.instances.sshd.roles.server.settings.authorizedKeys or {});
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
  };
}

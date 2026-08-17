{
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; }
  ({ den, config, lib, fclan, ... }: {
    imports = [
      inputs.den.flakeModule
      inputs.fmway-garden.flakeModules.clan
      (inputs.import-tree ./modules)
    ];

    # for debug
    den.hosts.x86_64-linux = builtins.mapAttrs (_: _: {}) config.clan.inventory.machines;
    den.schema.clan-machine.includes = [
      ({ clan-machine, ... }: lib.optionalAttrs (builtins.elem "local" clan-machine.tags) {
        # FAKE
        nixos.fileSystems."/" = lib.mkDefault
          { device = "/dev/sda1";
          fsType = "ext4";
        };
        nixos.boot.loader.grub.device = "/dev/sda2";
      })
    ];
    flake.lib = lib;
    flake.den = den;
    flake.fclan = fclan;
    _module.args.debug = true;

    debug = true;
    systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

    perSystem = { pkgs, system, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = [
          inputs.clan-core.packages.${system}.clan-cli
        ];
      };
    };

  });

  inputs = {
    clan-core = {
      url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    den.url = "github:denful/den/main";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    fmway-garden.url = "github:fmway/garden";
    import-tree.url = "github:denful/import-tree";
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";
  };
}

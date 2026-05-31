{
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; }
  ({ den, config, ... }: {
    imports = [
      inputs.den.flakeModule
      (inputs.import-tree ./modules)
    ];

    # for debug
    den.hosts.x86_64-linux = builtins.mapAttrs (_: _: {}) den.clan.inventory.machines;

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
    import-tree.url = "github:denful/import-tree";
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";
  };
}

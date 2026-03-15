{
  inputs = {
    clan-core.url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
    nixpkgs.follows = "clan-core/nixpkgs";
    fmway-lib.url = "github:fmway/lib";
    fmway-lib.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      clan-core,
      nixpkgs,
      fmway-lib,
      ...
    }@inputs: fmway-lib.mkFlake {
      inherit inputs;
      specialArgs = {
        lib = [
          clan-core.inputs.nix-select.lib
          {
            clan = clan-core.clanLib;
          }
        ];
      };
      src = ./.;
    }
    {
      systems = [ "x86_64-linux" "aarch64-linux" ];
      clan.templates.disko.xfs = {
        path = ./templates/disk/xfs/default.nix;
        description = "Single disk schema with a GPT layout, xfs root filesystem";
      };
    };
}

{ ... }:
{
  _class = "clan.service";
  manifest.name = "nix-token";
  manifest.description = "Service module for managing and appending access-tokens in Nix configurations.";
  manifest.categories = [ "Utility" ];
  manifest.readme = builtins.readFile ./README.md;

  roles.default = {
    description = "Provides default role for handling access-token integration within the clanService.";
    interface = { lib, ... }:
    {
      options.share = lib.mkEnableOption "Whether to share the generated access-token file with other hosts. Set to true only if tokens are meant to be used across multiple hosts.";
    };
    perInstance = { instanceName, settings, ... }:
    {
      nixosModule = { lib, config, ... }:
      {
        nix.extraOptions = ''
          !include ${config.clan.core.vars.generators.nix-token.files."nix.conf".path}
        '';

        clan.core.vars.generators.nix-token = {
          files."nix.conf" = {
            secret = true;
            mode = "0644";
          };

          prompts."tokens".description = "paste tokens with format <github|gitlab|codeberg|...>=<token> ...";

          script = ''
            cat <<EOF > $out/nix.conf
              access-tokens = $(cat $prompts/tokens)
            EOF
          '';
          share = settings.share;
        };
      };
    };
  };
}

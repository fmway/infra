s:
{ config, pkgs, lib, ... }: let
  port'= config.services.vaultwarden.config.ROCKET_PORT;
  port = toString port';
  server_name = "vault.fmway.me";
in {
  clan.core.vars.generators.vaultwarden = {
    prompts."database-url" = {};
    files.env = {
      secret = true;
      owner = "vaultwarden";
      group = "vaultwarden";
    };
    script = ''
      echo "DATABASE_URL=$(< "$prompts/database-url")" > "$out/env"
    '';
  };
  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    environmentFile = [
      config.clan.core.vars.generators.vaultwarden.files.env.path
    ];
    config = {
      DOMAIN = "https://${server_name}";
      SIGNUPS_ALLOWED = false;

      ROCKET_ADDRESS = "0.0.0.0";
      ROCKET_PORT = 8222;

      ROCKET_LOG = "critical";
      LOG_FILE = "/var/lib/vaultwarden/access.log";

      ADMIN_TOKEN = "$argon2id$v=19$m=65540,t=3,p=4$eMmmJRyI4/B5+eI3VU6yReUVWrjfn3Ab28cUpMg2Kd0$TMnhkruZS6kki05XLujVXaWQLnQHoYWg7TOS3Y4jIQ4";
    };
  };

  networking.firewall.interfaces."zt+".allowedTCPPorts = [ port' ];
  security.acme = {
    certs.${server_name} = {
      group = "nginx";
      dnsProvider = "cloudflare";
      webroot = null;
      credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE =
        config.clan.core.vars.generators."dyndns-cloudflare-fmway.me".files."dyndns-cloudflare-fmway.me".path;
    };
  };
  services.nginx = {
    virtualHosts."vault.fmway.me" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${port}";
        proxyWebsockets = true;
      };
    };
  };
}

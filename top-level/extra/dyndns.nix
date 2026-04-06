s: { lib, config, pkgs, ... }: {
  config = let
    server_name = s.inventory.instances.dns.roles.server.settings.hostname;
  in lib.mkMerge [
    {
      clan.core.vars.generators."dyndns-cloudflare-fmway.me".files."dyndns-cloudflare-fmway.me" = {
        mode = "0660";
        group = "acme";
      };
      security.acme = {
        defaults.webroot = "/var/lib/acme/acme-challenge";
        defaults.extraLegoFlags = [ "--dns.propagation-wait" "60s" ];
        certs.${server_name} = {
          extraDomainNames = [ "*.${server_name}" ];
          group = "nginx";
          dnsProvider = "cloudflare";
          webroot = null;
          # postRun = ''
          #   ${pkgs.acl}/bin/setfacl -m \
          #     u:nginx:rx,u:nobody:rx \
          #     /var/lib/acme/${server_name}
          #
          #   # set permission on key file
          #   ${pkgs.acl}/bin/setfacl -m \
          #     u:nginx:r,u:nobody:r \
          #     /var/lib/acme/${server_name}/*.pem
          # '';
          credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE =
            config.clan.core.vars.generators."dyndns-cloudflare-fmway.me".files."dyndns-cloudflare-fmway.me".path;
        };
      };
      services.adguardhome.settings = {
        tls.server_name = server_name;
        # dns.bind_hosts = s.inventory.instances.zerotier.roles.moon.machines.opc1.settings.stableEndpoints;
      };
      services.nginx.virtualHosts."dyndns.clan" = {
        forceSSL = lib.mkForce false;
        enableACME = lib.mkForce false;
      };
      services.nginx.resolver.addresses = lib.mkForce [
        "127.0.0.${if config.services.resolved.settings.Resolve.DNSStubListener or "" != "no" then "53" else "1"}:53"
      ];
      users.users.nginx.extraGroups = [ "acme" ];
    }
    (let cfg = config.services.adguardhome; in lib.mkIf (cfg.enable && cfg.settings.tls.enabled or false) {
      services.nginx.appendHttpConfig = ''
        proxy_headers_hash_max_size 1024;
        proxy_headers_hash_bucket_size 128;
      '';
      # services.nginx.streamConfig = let
      #   ip = builtins.elemAt cfg.settings.dns.bind_hosts 0;
      #   fixIp = if !isNull (builtins.match ".*:.*" ip) then "[${ip}]" else ip;
      #   dns = "${fixIp}:${toString cfg.settings.dns.port}";
      # in /* nginx */ ''
      #   upstream adguard_dns_tcp {
      #     server ${dns};
      #   }
      #   upstream adguard_dns_udp {
      #     server ${dns};
      #   }
      #
      #   # DNS-over-TLS (DoT) - Port 853
      #   server {
      #       listen 853 ssl;
      #       proxy_pass adguard_dns_tcp;
      #       ssl_certificate /var/lib/acme/${server_name}/fullchain.pem;
      #       ssl_certificate_key /var/lib/acme/${server_name}/key.pem;
      #   }
      # '';
      services.nginx.virtualHosts."${server_name}" = rec {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = let
              ip = if cfg.host == "0.0.0.0" then "127.0.0.1" else cfg.host;
              fixIp = if !isNull (builtins.match ".*:.*" ip) then "[${ip}]" else ip;
            in "http://${fixIp}:${toString cfg.port}";
            proxyWebsockets = true;
          };
          # "/.well-known/".root = "/var/lib/acme/acme-challenge/";
          "/dns-query" = {
            proxyPass = "${locations."/".proxyPass}/dns-query";
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            '';
          };
        };
      };
    })
  ];
}

{ settings, peerMaps, lib, myLib, ... }:
{ config, pkgs, ... }: let
  cfg = config.services.adguardhome;
in {
  services.adguardhome = {
    enable = true;
    settings = {
      user_rules = builtins.concatMap (ip: let t = if isNull (builtins.match ".*:.*" ip) then "A" else "AAAA"; in map (domain:
        "||${domain}^$dnsrewrite=NOERROR;${t};${ip}"
      ) peerMaps.${ip}) (builtins.attrNames peerMaps);

      dns = rec {
        bind_hosts = [
          "0.0.0.0"
        ];
        port = settings.dnsPort;
        upstream_dns = [
          "https://dns.quad9.net/dns-query"
        ];
        bootstrap_dns = [
          "9.9.9.9"
          "149.112.112.10"
          "2620:fe::10"
          "2620:fe::fe:10"
        ];
        # disallow all unregistered clients
        disallowed_clients = [ "0.0.0.0/0" ];
        allowed_clients = builtins.attrNames peerMaps;
        fallback_dns = bootstrap_dns;

        trusted_proxies = [
          "127.0.0.0/8"
          "::1/128"
          (myLib.subnet config.clan.core.vars.generators.zerotier-ip-zerotier.files.ip.value)
        ];
      };

      tls = {
        enabled = true;
        port_https = 0;
        port_dns_over_tls = 853;
        port_dns_over_quic = 853;
        port_dnscrypt = 0;
        allow_unencrypted_doh = true;
      };
    };
  };

  networking.firewall.allowedUDPPorts = [ 853 settings.dnsPort 53 ];
  networking.firewall.allowedTCPPorts = [ cfg.port 853 53 settings.dnsPort ];
  networking.firewall.extraCommands = lib.mkIf (settings.dnsPort != 53) /* sh */ ''
    ip46tables -t nat -A PREROUTING -i "zt+" -p tcp --dport 53 -j REDIRECT --to-ports ${toString settings.dnsPort} || true
    ip46tables -t nat -A PREROUTING -i "zt+" -p udp --dport 53 -j REDIRECT --to-ports ${toString settings.dnsPort} || true
  '';
  networking.firewall.extraStopCommands = lib.mkIf (settings.dnsPort != 53) /* sh */ ''
    ip46tables -t nat -D PREROUTING -i "zt+" -p tcp --dport 53 -j REDIRECT --to-ports ${toString settings.dnsPort} || true
    ip46tables -t nat -D PREROUTING -i "zt+" -p udp --dport 53 -j REDIRECT --to-ports ${toString settings.dnsPort} || true
  '';

  services.resolved.settings = lib.mkIf (settings.dnsPort == 53) {
    Resolve.DNSStubListener = "no";
  };
}

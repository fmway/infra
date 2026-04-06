{ lib, config, ... }: let
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
}

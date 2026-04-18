{ inputs, config, pkgs, ... }:
{
  imports = [
  ];
  programs.starship.enable = true;
  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    btop
    net-tools
  ];

  programs.fish.enable = true;
  programs.fish.interactiveShellInit = /* fish */ ''
    printf '\e[5 q'
    fish_config theme choose ayu-mirage
  '';

  security.doas = {
    enable = true;
    extraRules = [
    {
      groups = [ "users" "wheel" ];
      keepEnv = true;
      persist = true;
      setEnv = [
        "PATH"
        "NIX_PATH"
      ];
    }
    ];
  };
  users.users.user.shell = pkgs.fish;
  users.users.root.shell = pkgs.fish;

  systemd.timers.restart-service = {
    timerConfig = {
      OnBootSec = "6h";
      OnUnitActiveSec = "6h";
      Unit = "restart-service.service";
    };
  };

  systemd.services.restart-service = {
    serviceConfig.Type = "oneshot";
    script = ''
      systemctl restart adguardhome.service vaultwarden.service
    '';
  };

  # boot.kernel.sysctl."net.ipv6.conf.ens3.disable_ipv6" = 1;
}

{ inputs, pkgs, ... }:
{
  imports = [
  ];
  programs.starship.enable = true;
  environment.systemPackages = with pkgs; [
    git
    wget
    curl
  ];

  programs.fish.enable = true;
  programs.fish.interactiveShellInit = /* fish */ ''
    printf '\e[5 q'
  '';

  security.sudo.wheelNeedsPassword = false;
  security.doas = {
    enable = true;
    extraRules = [
    {
      groups = [ "users" "wheel" ];
      keepEnv = true;
      # persist = true;
      noPass = true;
      setEnv = [
        "PATH"
        "NIX_PATH"
      ];
    }
    ];
  };
  users.users.user.shell = pkgs.fish;
}

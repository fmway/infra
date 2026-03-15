{
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 7d";
    dates = "Fri *-*-* 00:00:00";
  };
  nix.settings.trusted-users = [ "root" "@wheel" ];
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
    "pipe-operators"
  ];
}

{ inputs, lib, self, ... }:
{
  perSystem = { pkgs, system, ... }:
  {
    devShells.default = pkgs.mkShell {
      packages = [
        (inputs.clan-core.packages.${system}.clan-cli
        # optional: temporary patches, just to apply disko, really unnecessary
         /*
        .overrideAttrs (o: {
          patches = o.patches or [] ++ [
            (pkgs.replaceVars ./00-clan-template-disk.patch {
              template_dir = "${self.outPath}/templates";
            })
          ];
        })
        */
        )
      ];
    };
  };
}

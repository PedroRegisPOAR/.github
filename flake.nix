{
  description = "Este é o entrypoint público do Imobanco para desenvolvedores, sim um 'nix flake' :)";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        name = "imobanco-entrypoint";

        pkgsAllowUnfree = import nixpkgs {
          # inherit system;
          system = "x86_64-linux";
          config = { allowUnfree = true; };
        };

      in
      rec {

        templates = import ./templates;

        packages.checkNixFormat = pkgsAllowUnfree.runCommand "check-nix-format" { } ''
          ${pkgsAllowUnfree.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${./.}

          # For fix
          # find . -type f -iname '*.nix' -exec nixpkgs-fmt {} \;

          mkdir $out #sucess
        '';

        apps.${name} = flake-utils.lib.mkApp {
          inherit name;
          drv = packages.${name};
        };

        devShells.default = pkgsAllowUnfree.mkShell {
          buildInputs = with pkgsAllowUnfree; [
            bashInteractive
            coreutils
            curl
            gnumake
            patchelf
            poetry
            python3Full
            tmate
          ];

          shellHook = ''
            echo -e 'IMO \n Banco' | "${pkgsAllowUnfree.figlet}/bin/figlet" | cat
          '';
        };
      });
}

{
  description = "doomemacs";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    doomemacssrc = {
      url = "github:hlissner/doom-emacs";
      flake = "false";
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          # import nix packages
          pkgs = import nixpkgs {
            inherit system;
          };

          # Utility to run a script easily in the flakes app
          simple_script = name: add_deps: text: let
            exec = pkgs.writeShellApplication {
              inherit name text;
              runtimeInputs = with pkgs; [
                emacs29
              ] ++ add_deps;
            };
          in {
            type = "app";
            program = "${exec}/bin/name";
          };

        in with pkgs;
          {
            ###################################################################
            #                             scripts                             #
            ###################################################################
            # apps = {
            #   default = simple_script "build" [] ''
              
            #   '';

            # };

            ###################################################################
            #                             scripts                             #
            ###################################################################
            packages = {

              default = mkDerivation {
                name = "doomemacs-3.0.0-pre";
                src = ./.;
                nativeBuildInputs = with pkgs; [
                  emacs29
                  git
                  (ripgrep.override {withPCRE2 = true;})
                ];
                buildPhase = ''
                   ${doomemacs}/bin/doom install --emacsdir ${doomemacssrc} --doomdir ${self}/.doom.d
                '';
                installPhase = ''
                   mkdir -p $out/share/emacsdir
                   mkdir -p $out/share/doomdir
                   cp -r ${doomemacssrc}/* ${out}/share/emacsdir
                   cp -r ${self}/.doom.d/* ${out}/share/doomdir
                   makeWrapper ${out}/share/emacsdir/bin/doom $out/bin/doom --add-flags "--emacsdir $out/share/emacsdir --doomdir $out/share/doomdir"
                   makeWrapper ${out}/share/emacsdir/bin/doom $out/bin/doomemacs --add-flags "--emacsdir $out/share/emacsdir --doomdir $out/share/doomdir run"
                '';               
              };
              
            }
            
            ###################################################################
            #                       development shell                         #
            ###################################################################
            devShells.default =
              mkShell
                {
                  nativeBuildInputs = with pkgs; [
                    emacs29
                    git
                    (ripgrep.override {withPCRE2 = true;})
                  ];
                };
          }
      );
}

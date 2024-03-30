{
  description = "doomemacs";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    doomemacssrc = {
      url = "github:hlissner/doom-emacs";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, doomemacssrc, ... }@inputs:
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

          doomdir = ".doom.d";
          emacsdir = "doom-emacsdir";

        in with pkgs;
          {
            ###################################################################
            #                             scripts                             #
            ###################################################################
            apps = {
              copy-doom-src = simple_script "build" [] ''
                echo "cp -r ${doomemacssrc}/ ./emacsdir"
                "$(which cp)"
                #cp -r "${doomemacssrc}/" ./emacsdir
              '';

            };

            ###################################################################
            #                             scripts                             #
            ###################################################################
            packages = {

              doomemacs = stdenv.mkDerivation {
                name = "doomemacs-3.0.0-pre";
                src = ./.;
                nativeBuildInputs = with pkgs; [
                  emacs29
                  git
                  (ripgrep.override {withPCRE2 = true;})
                  fzf
                  curl
                  makeWrapper
                  openssl
                ];
                buildInputs = with pkgs; [
                  emacs29
                  git
                  (ripgrep.override {withPCRE2 = true;})
                  fzf
                  curl
                  openssl
                ];
                unpackPhase = ''
                   echo "Copy emacsdir from doom src ${doomemacssrc} to ./${emacsdir}"
                   mkdir -p ./${emacsdir} ./${doomdir}
                   cp -r ${self}/${doomdir}/ ./${emacsdir}/
                   cp -r ${doomemacssrc}/* ./${emacsdir}/
                   find ./${emacsdir} -type d | xargs -n1 chmod 774
                   '';

                buildPhase = ''
                   echo "will run ./${emacsdir}/bin/doom --emacsdir ./${emacsdir} --doomdir ./${doomdir} install"
                   pwd
                   ls -la .
                   ./${emacsdir}/bin/doom --emacsdir ./${emacsdir} --doomdir ./${doomdir} install --force --debug --no-env --no-config
                '';
                installPhase = ''
                   mkdir -p $out/${emacsdir} $out/${doomdir}
                   cp -r $src/${emacsdir} $out/${emacsdir}/
                   find $out/${emacsdir} -type d | xargs -n1 chmod 774
                   echo "Copy doomdir from doom src  to $out/${doomdir}/"
                   cp -r ${self}/${doomdir}/* $out/${doomdir}
                   makeWrapper $out/share/emacsdir/bin/doom $out/bin/doom --add-flags
"--emacsdir $out/${emacsdir} --doomdir $out/${doomdir}"
                   makeWrapper $out/${emacsdir}/bin/doom $out/bin/doomemacs --add-flags "--emacsdir $out/${emacsdir} --doomdir $out/${doomdir} run"
                '';
              };
            };

            ###################################################################
            #                       development shell                         #
            ###################################################################
            devShells.default =
              mkShell
                {
                  nativeBuildInputs = (with pkgs; [
                    emacs29
                    git
                    (ripgrep.override {withPCRE2 = true;})
                    fzf
                    curl
                  ]);
                  # buildInputs = [
                  #   inputs.doomemacssrc
                  # ];

                  EMACSDIR="./emacsdir";
                  DOOMDIR="./.doom.d";

                  shellHook = ''
                    export PATH=$PATH:$EMACSDIR/bin
                    echo "$EMACSDIR - $DOOMDIR"
                  '';
                };
          }
      );
}

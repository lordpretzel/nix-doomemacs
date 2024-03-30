{
  description = "nix-doom-emacs shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-doom-emacs.url = "github:nix-community/nix-doom-emacs";
    doom-emacs = {
      url = "github:doomemacs/doomemacs";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, doom-emacs, ... }@inputs:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
          # doom-emacs = nix-doom-emacs.packages.${system}.default.override {
          #   doomPrivateDir = ./.doom.d;
          # };
          doomemacsdir = "doomemacsdir";
        in
          {
            devShells.default = pkgs.mkShell {
              buildInputs = with pkgs; [
                emacs29
                fzf
                gnugrep
                neofetch
                git
                gnumake
                eza
              ];

              shellHook = ''
        EMACS=${pkgs.emacs29}/bin/emacs
        source ${pkgs.git}/share/bash-completion/completions/git-prompt.sh
        GIT_PS1_SHOWDIRTYSTATE=true
        GIT_PS1_SHOWUNTRACKEDFILES=true
        GIT_DISCOVERY_ACROSS_FILESYSTEM=true
        source ${self}/shellsetup.sh
        source ${pkgs.fzf}/share/fzf/key-bindings.bash
	if [ ! -d ~/doomemacsdir ]; then cp -r ${self}/.doom.d/ ~/.doom.d; fi
	${self}/setup-doom.sh
        export PATH=${doomemacsdir}/bin:$PATH
        alias doomemacs="${pkgs.emacs29}/bin/emacs --init-directory \"$HOME/${doomemacsdir}\""
        '';
            };
          }
      );
}

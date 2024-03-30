{
  description = "nix-doom-emacs shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-doom-emacs.url = "github:nix-community/nix-doom-emacs";
  };

  outputs = { self, nixpkgs, flake-utils, nix-doom-emacs, ... }@inputs:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
          doom-emacs = nix-doom-emacs.packages.${system}.default.override {
            doomPrivateDir = "${self}/.doom.d";
          };
        in
          {
            devShells.default = pkgs.mkShell {
              buildInputs = [
                doom-emacs
              ] ++ (with pkgs; [
                fzf
                gnugrep
                neofetch
                git
                gnumake
              ]);

              shellHook = ''
        source ${self}/shellsetup.sh
      '';
            };
          }
      );
}

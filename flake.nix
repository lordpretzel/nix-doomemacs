{
  description = "nix-doom-emacs shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-doom-emacs.url = "github:nix-community/nix-doom-emacs";
  };

  outputs = { self, nixpkgs, nix-doom-emacs, ... }:
  let
    system = "aarch64-darwin";
    pkgs = import nixpkgs { inherit system; };
    doom-emacs = nix-doom-emacs.packages.${system}.default.override {
      doomPrivateDir = ./.doom.d;
    };
  in
  {
    devShells.${system}.default = pkgs.mkShell {
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
  };
}

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
            doomPrivateDir = ./.doom.d;
          };
        in
          {
            devShells.default = pkgs.mkShell {
              buildInputs = [
                doom-emacs
                pkgs.fzf
                pkgs.gnugrep
                pkgs.neofetch
                pkgs.git
                pkgs.gnumake
                pkgs.eza
              ];

              shellHook = ''
        source ${self}/shellsetup.sh
        source ${pkgs.fzf}/share/fzf/key-bindings.bash
        source ${pkgs.git}/share/bash-completion/completions/git-prompt.sh
        export GIT_PS1_SHOWDIRTYSTATE=true
        export GIT_PS1_SHOWUNTRACKEDFILES=true
        export GIT_DISCOVERY_ACROSS_FILESYSTEM=true
        PS1='\[\033[01;32m\]\u@\h\[\033[00m\]\[\033[01;31m\]$(__arch_prompt)\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[01;31m\]$(__git_ps1 " (%s)")\[\033[00m\] \n\[\033[01;31m\]$(__shell_nest_level)\[\033[00m\]\[\033[01;33m\]${?}\[\033[00m\]\$'
      '';
            };
          }
      );
}

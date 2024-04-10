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
          doomconfigdir = ".doomconfig";

          dependencies = with pkgs; [
            emacs29
            bat
            bashInteractive
            curl
            fzf
            gnugrep
            neofetch
            git
            gnumake
            eza
            glibcLocales
            nerdfonts
            htop
            btop
            gnutar
            bzip2
            wget
            direnv
            nix-direnv
            charasay
          ];

          # Utility to run a script easily in the flakes app
          simple_script = name: add_deps: text: let
            exec = pkgs.writeShellApplication {
              inherit name text;
              runtimeInputs = dependencies ++ add_deps;
            };
          in {
            type = "app";
            program = "${exec}/bin/${name}";
          };

          # script to use in package to setup and run doom
          rundoom = simple_script "run-doom.sh" [] ''
             ${pkgs.emacs29}/bin/emacs --init-directory "$HOME/${doomemacsdir}"
          '';

          setup-doom = simple_script "setup-doom.sh" [] ''
             export DOOMDIR=~/${doomconfigdir}
             export EMACS=${pkgs.emacs29}/bin/emacs
             export PATH=~/${doomemacsdir}/bin:$PATH
             if [ ! -d ~/${doomemacsdir} ]; then
                 mkdir -p ~/${doomemacsdir}
                 cp -r ${doom-emacs}/ ~/${doomemacsdir}/
             fi
             if [ ! -d ~/${doomconfigdir} ]; then
                 mkdir -p ~/${doomconfigdir}
                 cp -r ${self}/.doom.d/ ~/${doomconfigdir}
             fi
             find ~/${doomemacsdir} -type d -exec chmod 755 {} ''\\''\;
             find ~/${doomconfigdir} -type f -exec chmod +w {} ''\\''\;
             ~/${doomemacsdir}/bin/doom --emacsdir ~/${doomemacsdir} --doomdir ~/${doomconfigdir} install --no-config --env --force --debug
          '';

          boris-shell = simple_script "boris-shell.sh" [] ''
            nix develop github:lordpretzel/nix-doomemacs
          '';

#        source "$out/share/key-bindings.bash"
#        source "$out/share/shellsetup.sh"
        in with pkgs;
          {
            apps = {
              default = simple_script "boris-shell" [] ''
                 nix develop github:lordpretzel/nix-doomemacs
              '';
            };

            packages = {
              my-shell-and-doom = stdenv.mkDerivation {
                name = "my-shell-and-doom";

                src = ./.;

                runtimeInputs = dependencies;
                nativeBuildInputs = [ makeWrapper ];

                installPhase = ''
                   mkdir -p $out/bin/
                   mkdir -p $out/share/
                   cp $src/shellsetup.sh $out/share/shellsetup.sh
                   cp $src/.gitconfig $out/share/.gitconfig
                   cp ${boris-shell.program} $out/bin/boris-shell
                   cp ${rundoom.program} $out/bin/rundoom.sh
                   cp ${setup-doom.program} $out/bin/setup-doom.sh
                   cp ${pkgs.fzf}/share/fzf/key-bindings.bash $out/share/key-bindings.bash
                   makeWrapper $out/bin/setup-doom.sh $out/bin/setup-doom
                   makeWrapper $out/bin/rundoom.sh $out/bin/boris-doom
                '';
              };
            };

            devShells.default = pkgs.mkShell {
              buildInputs = dependencies;

              shellHook = ''
        unset LC_ALL
        export GIT_CONFIG=${self}/.gitconfig
        export EMACS=${pkgs.emacs29}/bin/emacs
        export DOOMDIR=~/${doomconfigdir}
        source ${pkgs.git}/share/bash-completion/completions/git-prompt.sh
        eval "$(${direnv}/bin/direnv hook bash)"
        source ${nix-direnv}/share/nix-direnv/direnvrc
        GIT_PS1_SHOWDIRTYSTATE=true
        GIT_PS1_SHOWUNTRACKEDFILES=true
        GIT_DISCOVERY_ACROSS_FILESYSTEM=true
        source ${self}/shellsetup.sh
        source ${pkgs.fzf}/share/fzf/key-bindings.bash
        export PATH=${doomemacsdir}/bin:$PATH
        alias doomemacs="${pkgs.emacs29}/bin/emacs --init-directory \"$HOME/${doomemacsdir}\""
        '';
            };
          }
      );
}

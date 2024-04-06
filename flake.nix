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

          dependencies = with pkgs; [
            emacs29
            bat
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
             if [ ! -d ~/${doomemacsdir} ]; then
                 cp -r ${doom-emacs}/ ~/${doomemacsdir}/
                 find ~/${doomemacsdir} -print0 -type d | xargs -n1 chmod 755
                 find ~/.doom.d -type f -print0 | xargs -n1 chmod +w
                 export PATH=~/${doomemacsdir}/bin:$PATH
                 ~/${doomemacsdir}/bin/doom install --emacsdir ~/${doomemacsdir} --no-config --env --force
                 if [ ! -d ~/.doom.d ]; then cp -r ${self}/.doom.d/ ~/.doom.d; fi
             fi
          '';

          boris-shell = simple_script "boris-shell.sh" [] ''
        unset LC_ALL
        export EMACS=${pkgs.emacs29}/bin/emacs
        export PATH=${doomemacsdir}/bin:$PATH
        alias doomemacs="${pkgs.emacs29}/bin/emacs --init-directory ~/${doomemacsdir}"
          '';

#        source "$out/share/key-bindings.bash"
#        source "$out/share/shellsetup.sh"
        in with pkgs;
          {
            apps = {
              setup-doom = simple_script "setup-doom-sh" [] ''
                 export EMACS=${pkgs.emacs29}/bin/emacs
                 if [ ! -d ~/${doomemacsdir} ]; then
                    cp -r ${doom-emacs}/ ~/${doomemacsdir}
                 fi
                 #find ~/${doomemacsdir} | xargs -n1 chmod +w
                 #find ~/.doom.d | xargs -n1 chmod +w
                 export PATH=~/${doomemacsdir}/bin:$PATH
                 ~/${doomemacsdir}/bin/doom install --emacsdir ~/${doomemacsdir} --debug --env --no-config --force
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
                   cp ${boris-shell.program} $out/bin/boris-shell.sh
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
        source ${pkgs.git}/share/bash-completion/completions/git-prompt.sh
        GIT_PS1_SHOWDIRTYSTATE=true
        GIT_PS1_SHOWUNTRACKEDFILES=true
        GIT_DISCOVERY_ACROSS_FILESYSTEM=true
        source ${self}/shellsetup.sh
        source ${pkgs.fzf}/share/fzf/key-bindings.bash
        if [ ! -d ~/.doom.d ]; then cp -r ${self}/.doom.d/ ~/.doom.d; fi
        if [ ! -d ~/${doomemacsdir} ]; then cp -r ${doom-emacs}/ ~/${doomemacsdir}; fi
        export PATH=${doomemacsdir}/bin:$PATH
        alias doomemacs="${pkgs.emacs29}/bin/emacs --init-directory \"$HOME/${doomemacsdir}\""
        '';
            };
          }
      );
}

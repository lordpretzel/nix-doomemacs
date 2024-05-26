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

          edpfdependencies = with pkgs; [
            emacsPackages.pdf-tools
          ];

          dependencies = (with pkgs; [
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
            tmux
            charasay
          ]) ++ edpfdependencies;

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

          script_with_correct_bash = name: add_deps: text:
            let
              runtimeInputs = dependencies ++ add_deps;

              path = pkgs.lib.makeBinPath runtimeInputs;
              # path = "test";
              thepath = ''
                       export PATH="${path}:$PATH"
              '';

              new_text = ''
                  #!${pkgs.bashInteractive}/bin/bash

                  ${thepath}
                  ${text}
              '';
            in
              pkgs.writeScriptBin name new_text;

          app_with_correct_bash = name: add_deps: text: let
            exec = script_with_correct_bash name add_deps text;
          in {
            type = "app";
            program = "${exec}/bin/${name}";
          };

          # script to use in package to setup and run doom
          rundoom = app_with_correct_bash "run-doom.sh" [] ''
             ${pkgs.emacs29}/bin/emacs --init-directory "$HOME/${doomemacsdir}"
          '';


          setup-doom = app_with_correct_bash "setup-doom.sh" [] ''
             export DOOMDIR=~/${doomconfigdir}
             export EMACS=${pkgs.emacs29}/bin/emacs
             export PATH=~/${doomemacsdir}/bin:$PATH
             export SHELL=${pkgs.bashInteractive}/bin/bash
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
             cp -s $(${pkgs.findutils}/bin/find ${pkgs.emacsPackages.pdf-tools}/ -name epdfinfo) ~/${doomemacsdir}/bin/epdfinfo
             ~/${doomemacsdir}/bin/doom --emacsdir ~/${doomemacsdir} --doomdir ~/${doomconfigdir} install --no-config --env --force --debug
          '';

          bashrc =
            let
              path = pkgs.lib.makeBinPath dependencies;
              thepath = ''
                       export PATH="${path}:$PATH"
              '';
            in
            pkgs.writeTextFile {
            name = "share/bashrc";
            text = ''
            if [ -f ~/.bashrc ]; then
              . ~/.bashrc
            fi
            unset LC_ALL
            export GIT_CONFIG=@@out@@/share/.gitconfig
            export EMACS=${pkgs.emacs29}/bin/emacs
            export DOOMDIR=~/${doomconfigdir}
            export SHELL=${pkgs.bashInteractive}/bin/bash
            source ${pkgs.git}/share/bash-completion/completions/git-prompt.sh
            eval "$(${pkgs.direnv}/bin/direnv hook bash)"
            source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
            GIT_PS1_SHOWDIRTYSTATE=true
            GIT_PS1_SHOWUNTRACKEDFILES=true
            GIT_DISCOVERY_ACROSS_FILESYSTEM=true
            source @@out@@/share/shellsetup.sh
            source ${pkgs.fzf}/share/fzf/key-bindings.bash
            export PATH=~/${doomemacsdir}/bin:$PATH
            ${thepath}
            alias doomemacs="${pkgs.emacs29}/bin/emacs --init-directory \"$HOME/${doomemacsdir}\""
        '';
          };

          boris-shell = app_with_correct_bash "boris-shell.sh" [] ''
            bash --rcfile @@out@@/share/bashrc
          '';
          #            NIX_BUILD_SHELL=${pkgs.bashInteractive}/bin/bash  nix develop github:lordpretzel/nix-doomemacs
        in with pkgs;
          {
            apps = {
              default = app_with_correct_bash "boris-shell" [] ''
                 NIX_BUILD_SHELL=${pkgs.bashInteractive}/bin/bash nix develop github:lordpretzel/nix-doomemacs
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
                   cp ${bashrc} $out/share/bashrc
                   substituteInPlace $out/share/bashrc --replace @@out@@ $out
                   cp ${boris-shell.program} $out/bin/boris-shell
                   substituteInPlace $out/bin/boris-shell --replace @@out@@ $out
                   cp ${rundoom.program} $out/bin/rundoom
                   cp ${setup-doom.program} $out/bin/setup-doom
                   cp ${pkgs.git}/share/bash-completion/completions/git-prompt.sh $out/share/git-prompt.sh
                   cp ${pkgs.fzf}/share/fzf/key-bindings.bash $out/share/key-bindings.bash
                   ln -s $(${pkgs.findutils}/bin/find ${pkgs.emacsPackages.pdf-tools}/ -name epdfinfo) $out/bin/my-epdfinfo
                '';
              };
            };

            devShells.default = pkgs.mkShell {
              buildInputs = dependencies;

              NIX_BUILD_SHELL = "${pkgs.bashInteractive}/bin/bash";
              shell = "${pkgs.bashInteractive}/bin/bash";

              shellHook = ''
        unset LC_ALL
        export GIT_CONFIG=${self}/.gitconfig
        export EMACS=${pkgs.emacs29}/bin/emacs
        export DOOMDIR=~/${doomconfigdir}
        export SHELL=${pkgs.bashInteractive}/bin/bash
        source ${pkgs.git}/share/bash-completion/completions/git-prompt.sh
        eval "$(${direnv}/bin/direnv hook bash)"
        source ${nix-direnv}/share/nix-direnv/direnvrc
        GIT_PS1_SHOWDIRTYSTATE=true
        GIT_PS1_SHOWUNTRACKEDFILES=true
        GIT_DISCOVERY_ACROSS_FILESYSTEM=true
        source ${self}/shellsetup.sh
        source ${pkgs.fzf}/share/fzf/key-bindings.bash
        export PATH=~/${doomemacsdir}/bin:$PATH
        alias doomemacs="${pkgs.emacs29}/bin/emacs --init-directory \"$HOME/${doomemacsdir}\""
        '';
            };
          }
      );
}

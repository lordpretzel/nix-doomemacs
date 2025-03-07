if [[ "$OSTYPE" == "linux-gnu" ]]; then
	MYOS="linux"
	if [ -f /etc/proc ] && [ "$(cat /etc/proc | grep Ubuntu)" != "" ]; then
	    LINUX_FLAVOR="ubuntu"
        fi
        if [ -x "$(command -v lsb_release)" ]; then
	    if [[ "$(lsb_release -i -s | grep NixOS)" != "" ]]; then
	        LINUX_FLAVOR="nixos"
	    fi
        fi
        export LINUX_FLAVOR
elif [[ "$OSTYPE" == "darwin"* ]]; then
	MYOS="osx"
	if [[ "$(arch)" == "arm64" ]]; then
	    M1=1
	else
	    M1=0
	fi
	export M1
elif [[ "$OSTYPE" == "cygwin" ]]; then
	MYOS="cygwin"
elif [[ "$OSTYPE" == "msys" ]]; then
	MYOS="windows"
elif [[ "$OSTYPE" == "win32" ]]; then
	MYOS="windows"
elif [[ "$OSTYPE" == "freebsd"* ]]; then
	MYOS="freebsd"
else
	MYOS="unknown"
fi
export MYOS

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    echo "Set linux locales"
    #export LC_ALL="en_US.UTF-8/UTF-8"
    export LANG="en_US.UTF-8/UFT-8"
else
    export LC_ALL="en_US.UTF-8"
    export LANG="en_US.UTF-8"
fi
if [ -x "$(command -v exa)" ]; then
    alias l="exa -a --group-directories-first --color=always"
    alias ll="exa -la --group-directories-first --color=always"
    alias lt="exa -aT --group-directories-first --color=always"
    alias llt="exa -alT --git --group-directories-first --color=always"
else
    alias l="ls -a"
    alias ll="ls -lah"
    alias lt="tree"
fi
if [ "$MYOS" == "linux" ]; then
    if [ -x /usr/bin/dircolors ]; then
	    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
	    alias ls='ls --color=auto'

	    alias grep='grep --color=auto'
	    alias fgrep='fgrep --color=auto'
	    alias egrep='egrep --color=auto'
    fi
fi
alias wh="which"
alias duse="du -h -d 0"
alias dh="df -h"
if [ $MYOS == "linux" ]; then
    alias o="xdg-open"
fi
if [ $MYOS == "osx" ]; then
    alias o="open"
fi
alias g="git"
alias nr="nix run"
alias ns="nix shell"
alias nd="nix develop"
if [ "${M1}" == "1" ]; then
    if [ -f /opt/homebrew/etc/bash_completion.d/git-prompt.sh ]; then
        source /opt/homebrew/etc/bash_completion.d/git-prompt.sh
        HAVE_GIT_PROMPT=1
    fi
    if [ -f  /opt/homebrew/etc/bash_completion.d/git-completion.bash ]; then
        source /opt/homebrew/etc/bash_completion.d/git-completion.bash
    elif  [ -f $HOME/scripts/git-completion.sh ]; then
        source $HOME/scripts/shell-scripts/git-completion.sh
    fi
else
    if [ -f /usr/local/etc/bash_completion.d/git-prompt.sh ]; then
        source /usr/local/etc/bash_completion.d/git-prompt.sh
        HAVE_GIT_PROMPT=1
    fi
    if [ -f  /usr/local/etc/bash_completion.d/git-completion.bash ]; then
        source /usr/local/etc/bash_completion.d/git-completion.bash
    elif  [ -f $HOME/scripts/git-completion.sh ]; then
        source $HOME/scripts/shell-scripts/git-completion.sh
    fi
fi

function __shell_nest_level() {
    LEVEL=`expr $SHLVL - 1`
    if [ "${LEVEL}" == "0" ]; then
        printf ""
    else
        printf "[+${LEVEL}] "
    fi
    if [ "X${IN_NIX_SHELL}" != "X" ]; then
        printf "[nix-shell] "
    fi
}

export -f __shell_nest_level

if [ "${MYOS}" == "osx" ]; then
    function __arch_prompt() {
        printf "[$(arch)]"
    }
else
    function __arch_prompt() {
        printf ""
    }
fi

export -f __arch_prompt

PS1='\[\033[01;32m\]\u@\h\[\033[00m\]\[\033[01;31m\]$(__arch_prompt)\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[01;31m\] $(__shell_nest_level)\[\033[00m\]\[\033[01;33m\][${?}]\[\033[00m\]\[\033[01;31m\]$(__git_ps1 " (%s)")\[\033[00m\] \n\[\033[01;34m\][my-term]\[\033[00m\] \$'

if [ "$MYOS" != "linux" ]; then
    export CLICOLOR=1 #cons25
    export LSCOLORS='ExGxFxdxCxDxDxBxBxExEx'
fi

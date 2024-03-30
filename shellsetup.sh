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
	    #alias dir='dir --color=auto'
	    #alias vdir='vdir --color=auto'

	    alias grep='grep --color=auto'
	    alias fgrep='fgrep --color=auto'
	    alias egrep='egrep --color=auto'
    fi
fi

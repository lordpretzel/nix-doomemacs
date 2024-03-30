doomemacsdir=doomemacsdir
if [ ! -d ~/doomemacsdir ]; then
    cp -r ${doom-emacs}/ ~/${doomemacsdir}/
    find ~/${doomemacsdir} -type d | xargs -n1 chmod 755
    find ~/${doomemacsdir} -type f | xargs -n1 chmod +w
    find ~/.doom.d -type f | xargs -n1 chmod +w
    export PATH=~/${doomemacsdir}/bin:$PATH
    ~/${doomemacsdir}/bin/doom install --emacsdir ~/${doomemacsdir}
fi

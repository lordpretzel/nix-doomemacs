doomemacsdir=doomemacsdir
if [ ! -d "${HOME}/doomemacsdir" ]; then
    cp -r ${doom-emacs}/ "${HOME}/${doomemacsdir}/"
    find "${HOME}/${doomemacsdir}" -type d | xargs -n1 chmod 755
    find "${HOME}/${doomemacsdir}" -type f | xargs -n1 chmod +w
    if [ -d "${HOME}/.doom.d" ]; then
       find "${HOME}/.doom.d" -type f | xargs -n1 chmod +w
    fi
    export PATH="${HOME}/${doomemacsdir}"/bin:$PATH
    "${HOME}/${doomemacsdir}"/bin/doom install --emacsdir "${HOME}/${doomemacsdir}"
fi

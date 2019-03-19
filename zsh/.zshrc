# Correctly display UTF-8 with combining characters.
if [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
	setopt combiningchars
fi

disable log

[ -r "/etc/zshrc_$TERM_PROGRAM" ] && . "/etc/zshrc_$TERM_PROGRAM"

export GPG_TTY="$(tty)"
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent

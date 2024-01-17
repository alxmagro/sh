#!/bin/bash

set -e # flag exit if error

echo -e '\e[0;33mSetting OS customs...\e[0m'

tee ~/.bash_custom > /dev/null <<EOF
if [ -n "\$SUDO_USER" ]; then
  PS1='\${debian_chroot:+(\$debian_chroot)}\[\033[01;32m\]\w\[\033[00m\]\\\$ '
else
  PS1='\${debian_chroot:+(\$debian_chroot)}\[\033[01;34m\]\w\[\033[00m\]\\\$ '
fi

# enhance cd to switch nvm node version automatically
cd() {
  builtin cd "$@"
  if [[ -f .nvmrc ]]; then
    nvm use > /dev/null
  fi
}

EOF
echo '[[ -s ~/.bash_custom ]] && source ~/.bash_custom' >> ~/.bashrc

echo -e '\e[0;33mFixing dual booting different times (windows/linux)...\e[0m'

timedatectl set-local-rtc 1 --adjust-system-clock

echo -e '\e[0;33mDone!\e[0m'
echo -e '\e[0;33mReboot your system and have fun :)\e[0m'

set +e

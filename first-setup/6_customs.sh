#!/bin/bash

set -e # flag exit if error

echo "# Setting OS customs..."

tee ~/.bash_custom > /dev/null <<EOF
if [ -n "\$SUDO_USER" ]; then
  PS1='\${debian_chroot:+(\$debian_chroot)}\[\033[01;32m\]\w\[\033[00m\]\\\$ '
else
  PS1='\${debian_chroot:+(\$debian_chroot)}\[\033[01;34m\]\w\[\033[00m\]\\\$ '
fi

EOF
echo '[[ -s ~/.bash_custom ]] && source ~/.bash_custom' >> ~/.bashrc

echo "# Fix dual booting different times (windows/linux)"

timedatectl set-local-rtc 1 --adjust-system-clock

echo "Fone!"
echo "Reboot your system and have fun!"

set +e

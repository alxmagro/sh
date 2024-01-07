#!/bin/bash

set -e # flag exit if error

NVM_VER=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | \
          grep "tag_name" | \
          cut -d '"' -f 4)

echo -e '\e[0;33mInstalling gitg...\e[0m'

sudo apt-get install gitg -y > /dev/null

echo -e '\e[0;33mInstalling rvm...\e[0m'

gpg --keyserver keyserver.ubuntu.com \
    --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
                7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable > /dev/null

echo -e '\e[0;33mInstalling nvm...\e[0m'

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VER/install.sh | bash > /dev/null

echo -e '\e[0;33mInstalling pgadmin4...\e[0m'

curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | \
  sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg

sudo sh -c '. /etc/os-release && echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$UBUNTU_CODENAME pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'

sudo apt-get install pgadmin4-web
sudo /usr/pgadmin4/bin/setup-web.sh

echo -e '\e[0;33mInstalling insomnia...\e[0m'

echo "deb [trusted=yes arch=amd64] https://download.konghq.com/insomnia-ubuntu/ default all" \
  | sudo tee -a /etc/apt/sources.list.d/insomnia.list

sudo apt-get update > /dev/null
sudo apt-get install insomnia -y > /dev/null

echo -e '\e[0;33mDone!\e[0m'
echo -e '\e[0;33mNow, move RVM script source from ~/.bash_profile to ~/.bashrc, to turn it always on.\e[0m'

set +e

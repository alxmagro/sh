#!/bin/bash

# STEP 1: Prompt and Dependencies

# flag exit if error
set -e

# Setup variables
. /etc/os-release # fetch $UBUNTU_CODENAME
RVM_RECV_KEYS="409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB"
NVM_VER=$( \
  curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | \
  grep "tag_name" | \
  cut -d '"' -f 4 \
)
DOCKER_ROOT="$HOME/.docker"

# update and install script dependencies
sudo apt-get update
sudo apt-get install curl wget gnupg2 xclip -y

# STEP 2: Apps

# install Google Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt-get install ./google-chrome-stable_current_amd64.deb -y

# install VSCode
sudo apt install software-properties-common apt-transport-https wget -y
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
sudo apt-get install code

# install Spotify
curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | \
  sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb http://repository.spotify.com stable non-free" | \
  sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt-get update && sudo apt-get install spotify-client

# STEP 3: Dev Tools

# install gitg
sudo apt-get install gitg -y

# install Ruby Version Manager (rvm)
gpg --keyserver keyserver.ubuntu.com --recv-keys $RVM_RECV_KEYS
curl -sSL https://get.rvm.io | bash -s stable

# install Node Version Manager (nvm)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VER/install.sh | bash

# STEP 4: Docker

# setup docker repository
sudo apt-get install ca-certificates curl gnupg lsb-release
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# install docker
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# configure daemon data directory
sudo systemctl stop docker.socket
sudo service docker stop

sudo mv /var/lib/docker $DOCKER_ROOT

sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "data-root": "$DOCKER_ROOT"
}
EOF

# set docker permissions
sudo chown -R $USER:$USER $DOCKER_ROOT
sudo usermod -aG docker $USER

# add aliases to $HOME/.bash_aliases
tee -a $HOME/.bash_aliases > /dev/null << EOF
alias dcu="sudo docker compose up"
alias dcd="sudo docker compose down"
alias dce="sudo docker compose exec"
alias dcr="sudo docker compose run"
EOF

# STEP 5: Git

# get info
read -p "Enter your git name: " GIT_NAME
read -p "Enter your git email: " GIT_EMAIL
read -p "Enter your SSH passphrase: " SSH_PASSPHRASE

# set git globals
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

# generate SSH keys
ssh-keygen -t ed25519 -C "$SSH_PASSPHRASE"

# FINAL

# copy public key to clipboard
cat $HOME/.ssh/id_ed25519.pub | xclip -selection clipboard

# print message
echo "---
Script finished sucessfully!

You still need to do a few things before using the system:

1. Move RVM script source from ~/.bash_profile to ~/.bashrc, to turn it always on;
2. Paste your SSH key into Github settings (it's already on your clipboard!);
3. Reboot system;"

# flag exit if error
set +e

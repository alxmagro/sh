#!/bin/bash

# SECTION: Prompt and Dependencies

set -e # flag exit if error

echo "# Install script dependencies"

sudo apt-get update > /dev/null
sudo apt-get install curl wget gnupg2 xclip -y > /dev/null

echo "# Setup variables"

. /etc/os-release # fetch $UBUNTU_CODENAME

NVM_VER=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | \
          grep "tag_name" | \
          cut -d '"' -f 4)
DOCKER_ROOT="$HOME/.docker"

# SECTION: Apps

echo "# Install Google Chrome"

wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt-get install ./google-chrome-stable_current_amd64.deb -y > /dev/null

echo "# Install VS Code"

sudo apt-get install software-properties-common apt-transport-https wget -y > /dev/null
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
sudo apt-get install code -y > /dev/null

echo "# Install Spotify"

curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | \
  sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb http://repository.spotify.com stable non-free" | \
  sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt-get update > /dev/null
sudo apt-get install spotify-client -y > /dev/null

# SECTION: Dev Tools

echo "# Install gitg"

sudo apt-get install gitg -y > /dev/null

echo "# Install rvm"

gpg --keyserver keyserver.ubuntu.com \
    --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
                7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable > /dev/null

echo "# Install nvm"

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VER/install.sh | bash > /dev/null

# SECTION: Docker

echo "# Install docker dependencies"

sudo apt-get install ca-certificates curl gnupg lsb-release -y > /dev/null

echo "# Add docker's official GPG key"

sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "# Setup docker repository"

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update > /dev/null

echo "# Install docker"

sudo apt-get install docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin -y > /dev/null

echo "# Configure docker daemon (data-root)"

sudo systemctl stop docker.socket
sudo service docker stop

sudo mv /var/lib/docker $DOCKER_ROOT

sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "data-root": "$DOCKER_ROOT"
}
EOF

echo "# Configure docker permissions"

sudo chown -R $USER:$USER $DOCKER_ROOT
sudo usermod -aG docker $USER

echo "# Add docker aliases"

tee -a $HOME/.bash_aliases > /dev/null << EOF
alias dcu="sudo docker compose up"
alias dcd="sudo docker compose down"
alias dce="sudo docker compose exec"
alias dcr="sudo docker compose run"
EOF

# SECTION: Git

read -p "Enter your git name: " GIT_NAME
read -p "Enter your git email: " GIT_EMAIL

echo "# Set git globals"

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

echo "# Generate SSH keys (and copy it to your clipboard)"

ssh-keygen -t ed25519 -C "$GIT_EMAIL"
cat $HOME/.ssh/id_ed25519.pub | xclip -selection clipboard

# STEP 6: Customize bash

tee ~/.bash_custom > /dev/null <<EOF
if [ -n "\$SUDO_USER" ]; then
  PS1='\${debian_chroot:+(\$debian_chroot)}\[\033[01;32m\]\w\[\033[00m\]\\\$ '
else
  PS1='\${debian_chroot:+(\$debian_chroot)}\[\033[01;34m\]\w\[\033[00m\]\\\$ '
fi

EOF

echo '[[ -s ~/.bash_custom ]] && source ~/.bash_custom' >> ~/.bashrc

# SECTION: Final

echo "
# Script finished sucessfully!

You still need to do a few things before using the system:

1. Paste your SSH key into Github settings;
2. Move RVM script source from ~/.bash_profile to ~/.bashrc, to turn it always on;
3. Reboot system;"

set +e

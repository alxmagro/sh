#!/bin/bash

set -e # flag exit if error

DOCKER_ROOT="$HOME/.docker"

echo "# Installing docker..."

curl https://get.docker.com/ | bash -

echo "# Setting docker daemon..."

sudo systemctl stop docker.socket
sudo service docker stop

sudo mv /var/lib/docker $DOCKER_ROOT

sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "data-root": "$DOCKER_ROOT"
}
EOF

echo "# Setting docker permissions..."

sudo chown -R $USER:$USER $DOCKER_ROOT
sudo usermod -aG docker $USER

echo "# Adding docker aliases..."

tee -a $HOME/.bash_aliases > /dev/null << EOF
alias dcu="sudo docker compose up"
alias dcd="sudo docker compose down"
alias dce="sudo docker compose exec"
alias dcr="sudo docker compose run"
EOF

echo "Done!"

set +e

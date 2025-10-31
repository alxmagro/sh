#!/bin/bash

set -e # flag exit if error

echo -e '\e[0;33mInstalling Google Chrome...\e[0m'

wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt-get install ./google-chrome-stable_current_amd64.deb -y > /dev/null

echo -e '\e[0;33mInstalling VS Code...\e[0m'

sudo apt-get install software-properties-common apt-transport-https wget -y > /dev/null
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
sudo apt-get install code -y > /dev/null

echo -e '\e[0;33mInstalling Spotify...\e[0m'

curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | \
  sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb http://repository.spotify.com stable non-free" | \
  sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt-get update > /dev/null
sudo apt-get install spotify-client -y > /dev/null

echo -e '\e[0;33mDone!\e[0m'

set +e

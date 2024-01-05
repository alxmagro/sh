#!/bin/bash

echo -e '\e[0;33mInstalling dependencies...\e[0m'

sudo apt-get update > /dev/null
sudo apt-get install curl wget gnupg2 xclip -y > /dev/null

echo -e '\e[0;33mDone!\e[0m'

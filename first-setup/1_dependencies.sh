#!/bin/bash

echo "Installing dependencies..."

sudo apt-get update > /dev/null
sudo apt-get install curl wget gnupg2 xclip -y > /dev/null

echo "Done!"

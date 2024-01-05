#!/bin/bash

set -e # flag exit if error

read -p "Enter your git name: " GIT_NAME
read -p "Enter your git email: " GIT_EMAIL

echo "# Setting git globals..."

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

echo "# Generating SSH keys (and copy it to your clipboard)..."

ssh-keygen -t ed25519 -C "$GIT_EMAIL"
cat $HOME/.ssh/id_ed25519.pub | xclip -selection clipboard

echo "Done!"
echo "Please add the SSH key to your GitHub account settings."
echo "1. Visit https://github.com/settings/keys."
echo "2. Click on 'New SSH key' or 'Add SSH key'."
echo "3. Paste the copied key into the 'Key' field."
echo "4. Click 'Add SSH key' or 'Save'."
echo "Your SSH key is now linked to your GitHub account."

set +e

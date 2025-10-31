#!/bin/bash

set -e # flag exit if error

read -p "Enter your git name: " GIT_NAME
read -p "Enter your git email: " GIT_EMAIL

echo -e '\e[0;33mSetting git globals...\e[0m'

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

echo -e '\e[0;33mGenerating SSH keys (and copy it to your clipboard)...\e[0m'

ssh-keygen -t ed25519 -C "$GIT_EMAIL"
cat $HOME/.ssh/id_ed25519.pub | xclip -selection clipboard

echo -e '\e[0;33mDone!\e[0m'
echo -e '\e[0;33mPlease add the SSH key to your GitHub account settings.\e[0m'
echo -e '\e[0;33m1. Visit https://github.com/settings/keys.\e[0m'
echo -e '\e[0;33m2. Click on "New SSH key" or "Add SSH key".\e[0m'
echo -e '\e[0;33m3. Paste the copied key into the "Key" field.\e[0m'
echo -e '\e[0;33m4. Click "Add SSH key" or "Save".\e[0m'
echo -e '\e[0;33mYour SSH key is now linked to your GitHub account.\e[0m'

set +e

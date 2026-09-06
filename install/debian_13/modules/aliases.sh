#!/bin/bash
# desc: Configure bash aliases

set -e

log 'Adding shell aliases...'

## Debian's default .bashrc already sources ~/.bash_aliases, so there is
## nothing to wire up here.
write_block "$HOME/.bash_aliases" << 'EOF'
# Managed by nikit - rewritten on install, removed on `nikit uninstall`.
# Put your own aliases outside this block.

# files

alias ..='cd ..'

# docker

alias dcu="sudo docker compose up"
alias dcd="sudo docker compose down"
alias dce="sudo docker compose exec"
alias dcr="sudo docker compose run"

dprune-all() {
  docker rm -f $(docker ps -qa) # Remove every container
  docker system prune -af # Remove every unused container, image and network
  docker volume rm -f $(docker volume ls -q) # Remove every volume
}
EOF

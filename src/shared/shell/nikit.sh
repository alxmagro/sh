#!/bin/bash
#
# nikit - A shortcut for the commands named _nikit-*.
#
#   nikit app-folders sync   ==   _nikit-app-folders sync
#
# The real command is the prefixed one, and the prefix is not decoration: a
# bare `gnome-extensions` is already a program on any GNOME system, and ours
# would lose to it in PATH. Prefixing is what keeps the name ours; this only
# saves the typing.
#
# `uninstall` is handled here instead: there is nothing left to call once the
# files are gone.

_nikit_usage() {
  echo "Usage: nikit <command> [args]"
  echo
  echo "Commands:"
  echo "  app-folders        Sync, edit and restore your App Grid folders"
  echo "  gnome-extensions   Sync, edit and restore your GNOME Shell extensions"
  echo "  uninstall          Remove nikit's files and the ~/.bashrc hook"
}

# Delete nikit's marked block from a file, if the file is there.
_nikit_strip_block() {
  local file="$1"
  [ -f "$file" ] || return 0
  sed -i '/^# --- nikit start$/,/^# --- nikit end$/d' "$file"
}

# Remove everything the install put outside the repo: the data tree, the user
# config, the ~/.bashrc source line, and the marked block in ~/.bash_aliases
# and ~/.nanorc - dropping ~/.nanorc itself when nothing else is left in it.
# Pass -y to skip the prompt.
_nikit_uninstall() {
  local data config line reply yes=

  case "${1:-}" in
    -y | --yes) yes=1 ;;
    "") ;;
    *) echo "nikit uninstall: unknown option '$1'" >&2; return 1 ;;
  esac

  data="${XDG_DATA_HOME:-$HOME/.local/share}/nikit"
  config="${XDG_CONFIG_HOME:-$HOME/.config}/nikit"
  line='source ~/.local/share/nikit/init.sh'

  if [ -z "$yes" ]; then
    echo "Remove:"
    echo "  $data"
    echo "  $config"
    echo "  '$line' from ~/.bashrc"
    echo "  the nikit block in ~/.bash_aliases"
    echo "  the nikit block in ~/.nanorc (the file too, if left empty)"
    printf 'Continue? [y/N] '
    read -r reply
    case "$reply" in
      y | Y | yes) ;;
      *) echo "Aborted."; return 1 ;;
    esac
  fi

  rm -rf "$data" "$config"

  if [ -f "$HOME/.bashrc" ]; then
    sed -i '\|^source ~/\.local/share/nikit/init\.sh$|d' "$HOME/.bashrc"
  fi

  _nikit_strip_block "$HOME/.bash_aliases"

  _nikit_strip_block "$HOME/.nanorc"
  if [ -f "$HOME/.nanorc" ] && ! grep -q '[^[:space:]]' "$HOME/.nanorc"; then
    rm -f "$HOME/.nanorc"
  fi

  echo "Done. Open a new shell to drop the loaded commands."
}

nikit() {
  local command="${1:-}"

  case "$command" in
    app-folders | gnome-extensions)
      shift
      "_nikit-$command" "$@"
      ;;
    uninstall)
      shift
      _nikit_uninstall "$@"
      ;;
    -h | --help | help | '')
      _nikit_usage
      ;;
    *)
      echo "nikit: no such command '$command'" >&2
      echo >&2
      _nikit_usage >&2
      return 1
      ;;
  esac
}

# Completing the command name only. What each one takes after that is its own
# business, and none of them would gain much from being spelled out here.
#
# The names are read back out of the usage text rather than listed again, so a
# command added there is completed without touching anything else.
_nikit_complete() {
  [ "$COMP_CWORD" -eq 1 ] || return 0

  mapfile -t COMPREPLY < <(
    compgen -W "$(_nikit_usage | awk '/^  [a-z]/ { print $1 }')" \
      -- "${COMP_WORDS[COMP_CWORD]}"
  )
}

complete -F _nikit_complete nikit

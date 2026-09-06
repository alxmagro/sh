#!/bin/bash
#
# Helpers shared by every install script.
#
# Sourced once by install.sh, which exports SH_ROOT and SH_INSTALL before
# running anything. Scripts never source this themselves.

### Paths

# Install-owned files (wiped and rewritten each run) live here.
PROJECT_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/nikit"
# User-owned config (only seeded when missing) lives here.
CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/nikit"
export PROJECT_ROOT CONFIG_ROOT

SH_LOG_DIR="${TMPDIR:-/tmp}/sh-install"

### Output

# Progress line from inside a module, indented under its heading. Goes to
# stderr so it survives run() capturing the module's stdout.
log() {
  echo -e "\e[0;90m    $*\e[0m" >&2
}

success() {
  echo -e "\e[0;32m$*\e[0m" >&2
}

abort() {
  echo -e "\e[0;31m$*\e[0m" >&2
  exit 1
}

### Running

# Run one module. Its stdout goes to a log file so apt and friends stay
# quiet; stderr stays on the terminal so errors and prompts still show.
# The log is printed when the module fails.
run() {
  local path="$SH_ROOT/$1"
  local name log

  [ -f "$path" ] || abort "No such script: $1"

  name=$(basename "$1" .sh)

  # Honour an explicit module selection when install.sh set one.
  if [ -n "${SH_SELECTED:-}" ]; then
    case " $SH_SELECTED " in
      *" $name "*) ;;
      *) return 0 ;;
    esac
  fi

  log="$SH_LOG_DIR/$name.log"

  mkdir -p "$SH_LOG_DIR"
  echo -e "\e[0;34m- $name\e[0m"

  if ! bash "$path" > "$log"; then
    echo >&2
    echo -e "\e[0;31m$name failed, output follows:\e[0m" >&2
    echo >&2
    cat "$log" >&2
    exit 1
  fi
}

### Packages

# Read a package list, skipping comments and blank lines. Takes a path
# relative to the repo root, without the extension:
#
#   packages install/debian_13/dependencies
packages() {
  local file="$SH_ROOT/$1.packages"

  [ -f "$file" ] || abort "No such package list: $1.packages"

  grep -vE '^[[:space:]]*(#|$)' "$file"
}

### Files

# Create a directory if it is missing.
ensure_folder() {
  mkdir -p "$@"
}

# Append a line to a file, but only once.
append_once() {
  local file="$1" line="$2"

  [ -f "$file" ] || touch "$file"

  if ! grep -qxF "$line" "$file"; then
    echo "$line" >> "$file"
  fi
}

# Replace nikit's marked block in a file with the body read from stdin,
# leaving any lines the user keeps around it untouched. Creates the file if
# it is missing. `nikit uninstall` strips the same markers back out.
write_block() {
  local file="$1" body
  local begin='# --- nikit start' end='# --- nikit end'

  body=$(cat)

  [ -f "$file" ] || touch "$file"

  if grep -qxF "$begin" "$file"; then
    sed -i "/^$begin\$/,/^$end\$/d" "$file"
  fi

  # One blank line between the user's own lines and our block, never more.
  if [ -s "$file" ] && [ -n "$(tail -n1 "$file")" ]; then
    printf '\n' >> "$file"
  fi

  printf '%s\n%s\n\n%s\n' "$begin" "$body" "$end" >> "$file"
}

apt_update() {
  sudo apt-get update
}

apt_install() {
  sudo apt-get install -y "$@"
}

### Exports
#
# Scripts run in a child bash, which does not inherit shell functions
# unless they are exported.

export -f log success abort packages ensure_folder append_once write_block apt_update apt_install

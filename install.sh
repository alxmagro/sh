#!/bin/bash
#
# Two modes:
#   tty      ./install.sh                       Pick a distro, then its modules
#   inline   ./install.sh -d debian_13 [-m scripts,docker]
#
# --dry-run (inline only) prints the plan and runs nothing.

set -euo pipefail

SH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SH_INSTALL="$SH_ROOT/install"
export SH_ROOT SH_INSTALL

# shellcheck source=install/helpers/common.sh
source "$SH_INSTALL/helpers/common.sh"

# Distro names that ship an install (install/<name>/run.sh).
systems() {
  local dir

  for dir in "$SH_INSTALL"/*/; do
    [ -f "$dir/run.sh" ] && basename "$dir"
  done
}

# Module names for a distro, in the order its run.sh lists them.
modules() {
  grep -oE 'modules/[A-Za-z0-9_.-]+\.sh' "$SH_INSTALL/$1/run.sh" 2>/dev/null \
    | sed 's#.*/##; s#\.sh$##'
}

usage() {
  cat <<'EOF'
Usage:
  install.sh                          Pick a distro and its modules
  install.sh -d <distro>              Install every module for a distro
  install.sh -d <distro> -m a,b,c     Install only the modules named
  install.sh [...] --dry-run          Show the plan and exit, install nothing

Distros:
EOF
  systems | sed 's/^/  - /'
}

# True when /dev/tty can be opened, i.e. a real terminal is attached.
tty_available() {
  ( exec < /dev/tty ) 2>/dev/null
}

# True when a module is in the selection, or nothing was selected.
module_selected() {
  [ -z "${SH_SELECTED:-}" ] && return 0
  case " $SH_SELECTED " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

dry_run_plan() {
  local m
  echo "Dry run — $DISTRO, no modules ran:"
  modules "$DISTRO" | while read -r m; do
    if module_selected "$m"; then
      echo "  - $m"
    fi
  done
}

# --- arguments ---------------------------------------------------------

DRY_RUN=0
DISTRO=''
MODULES_CSV=''
MODULES_GIVEN=0

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)     usage; exit 0 ;;
    --dry-run)     DRY_RUN=1; shift ;;
    -d|--distro)   [ $# -ge 2 ] || abort "$1 needs a value"; DISTRO="$2"; shift 2 ;;
    --distro=*)    DISTRO="${1#*=}"; shift ;;
    -m|--modules)  [ $# -ge 2 ] || abort "$1 needs a value"; MODULES_CSV="$2"; MODULES_GIVEN=1; shift 2 ;;
    --modules=*)   MODULES_CSV="${1#*=}"; MODULES_GIVEN=1; shift ;;
    *)             abort "Unexpected argument: $1 (see --help)" ;;
  esac
done

# -m belongs to inline mode, which -d selects. --dry-run works in either mode.
[ -n "$DISTRO" ] || [ "$MODULES_GIVEN" -eq 0 ] || abort "-m needs -d"

# --- pick the distro and modules ------------------------------------

declare -a SELECTED=()

if [ -n "$DISTRO" ]; then
  # inline mode
  [ -d "$SH_INSTALL/$DISTRO" ] || abort "No install for '$DISTRO'. See --help."

  if [ "$MODULES_GIVEN" -eq 1 ]; then
    IFS=', ' read -ra SELECTED <<< "$MODULES_CSV"
    for name in "${SELECTED[@]}"; do
      modules "$DISTRO" | grep -qxF "$name" || abort "Unknown module: $name"
    done
  fi
else
  # tty mode
  tty_available || abort "No terminal. Use: install.sh -d <distro> [-m a,b,c]"

  if ! command -v gum > /dev/null; then
    log "Installing gum for the pickers"
    apt_update > /dev/null
    apt_install gum > /dev/null
  fi

  exec < /dev/tty

  # gum theme, picked up by every menu below.
  export GUM_CHOOSE_HEADER_FOREGROUND=''
  export GUM_CHOOSE_HEADER_MARGIN='0 0 1 0'
  export GUM_CHOOSE_CURSOR_FOREGROUND='6'
  export GUM_CHOOSE_SELECTED_FOREGROUND='6'
  export GUM_CHOOSE_SELECTED_PREFIX_FOREGROUND='6'

  mapfile -t choices < <(systems)
  DISTRO="$(gum choose --header 'Select a distro' "${choices[@]}")"
  [ -n "$DISTRO" ] || abort "Nothing selected."

  # Show "name - description" (from the module's `# desc:` line); nothing
  # preselected, the user marks what to install.
  labels=()
  while read -r name; do
    desc="$(sed -n 's/^# desc: //p' "$SH_INSTALL/$DISTRO/modules/$name.sh" | head -n1 || true)"
    labels+=("$name${desc:+ - $desc}")
  done < <(modules "$DISTRO")

  mapfile -t picked < <(
    gum choose --no-limit --height "$(( ${#labels[@]} + 3 ))" \
      --header 'Select the modules to run' \
      "${labels[@]}"
  )
  [ "${#picked[@]}" -gt 0 ] || abort "Nothing selected."

  SELECTED=()
  for label in "${picked[@]}"; do
    SELECTED+=("${label%% - *}")
  done
fi

if [ "${#SELECTED[@]}" -gt 0 ]; then
  SH_SELECTED="${SELECTED[*]}"
  export SH_SELECTED
fi

# --- run -----------------------------------------------------------

echo -e "\e[1mSetting up $DISTRO\e[0m"
echo

if [ "$DRY_RUN" -eq 1 ]; then
  dry_run_plan
  exit 0
fi

sudo -v || exit 1

# shellcheck source=/dev/null  # path known only at runtime
source "$SH_INSTALL/$DISTRO/run.sh"

success 'Done!'

#!/bin/bash

set -e

REPO="alxmagro/sh"
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/$REPO/$BRANCH"
API_BASE="https://api.github.com/repos/$REPO/contents"
DRY_RUN=false

### Gum theme

export GUM_CHOOSE_CURSOR_FOREGROUND="6"   # #006E9B
export GUM_CHOOSE_SELECTED_FOREGROUND="14" # #0096C7
export GUM_CHOOSE_HEADER_FOREGROUND="255"

### Args

for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=true ;;
  esac
done

### Gum

if ! command -v gum &>/dev/null; then
  echo "Installing gum..."
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
  echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y gum
fi

### Helpers

api_list_dirs() {
  curl -sf "$API_BASE/$1" | jq -r '.[] | select(.type == "dir") | .name'
}

api_list_files() {
  curl -sf "$API_BASE/$1" | jq -r '.[] | select(.type == "file") | .name' | sort
}

fetch_raw() {
  curl -sf "$RAW_BASE/$1"
}

print_dry() {
  local content="$1"
  local label="$2"

  gum style \
    --border normal \
    --border-foreground 240 \
    --padding "0 1" \
    --margin "0 0" \
    "$(gum style --foreground "#0071E3" --bold "$label")"

  echo "$content" | while IFS= read -r line; do
    printf "$(gum style --foreground 240 '|') %s\n" "$line"
  done
  echo
}

### Main

echo
gum style --foreground 255 --bold "Setup OS Installer"
$DRY_RUN && gum style --foreground 245 "dry-run"
echo

# Select OS
mapfile -t OS_LIST < <(api_list_dirs "setup-os")

if [ ${#OS_LIST[@]} -eq 0 ]; then
  echo "No OS directories found in repo."
  exit 1
fi

OS=$(gum choose --header "Select your operating system:" "${OS_LIST[@]}" < /dev/tty)
echo

# Select scripts
mapfile -t SCRIPT_LIST < <(api_list_files "setup-os/$OS")

if [ ${#SCRIPT_LIST[@]} -eq 0 ]; then
  echo "No scripts found for $OS."
  exit 1
fi

mapfile -t SELECTED < <(gum choose --no-limit --header "Select scripts to run:" "${SCRIPT_LIST[@]}" < /dev/tty)

if [ ${#SELECTED[@]} -eq 0 ]; then
  echo "No scripts selected."
  exit 0
fi

echo

# Select utils
mapfile -t UTILS_LIST < <(api_list_files "utils")

if [ ${#UTILS_LIST[@]} -gt 0 ]; then
  mapfile -t SELECTED_UTILS < <(gum choose --no-limit --header "Select utils to install (optional):" "${UTILS_LIST[@]}" < /dev/tty || true)
  echo
fi

# Run or dry-run
run_script() {
  local path="$1"
  local label="$2"
  local content
  content=$(fetch_raw "$path")

  if $DRY_RUN; then
    print_dry "$content" "$label"
  else
    gum style --foreground "#0071E3" "▶ Running $label..."
    echo "$content" | bash
    echo
  fi
}

for script in "${SELECTED[@]}"; do
  run_script "setup-os/$OS/$script" "$script"
done

for script in "${SELECTED_UTILS[@]}"; do
  run_script "utils/$script" "$script"
done

gum style --foreground 255 --bold "Done!"
echo

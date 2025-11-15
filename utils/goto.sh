#!/bin/bash
#
# Single-file script installer.
#
# Designed by Alexandre Magro (alexandremagro@live.com)
#
# goto - Jump to named target folders
#
# Usage:
#   goto <name>                    Jump to a folder inside the configured target directory
#   goto --add <name> <target>     Create a symlink inside the target directory
#   goto --config <key>            Read a config value
#   goto --config <key> <value>    Set a config value
#   goto --help                    Show this help message

# Configuration (stored in ~/.bash_scripts/config.json):
#   goto.path   => Base target directory
#   goto.mode   => '-P' or '-L' (navigates do physical directory by default)

# Examples:
#   goto --config path ~/MyFavoriteFolder
#   goto --config path ~/.goto_links
#   goto --config mode -L
#   goto --add Projects ~/Documents/Code/Projects
#   goto Projects

### Base Variables

TARGET_DIR="$HOME/.bash_scripts"
BASHRC="$HOME/.bashrc"
SCRIPT_FILENAME="goto"

### Base Functions

# Prompt for a value and return it
prompt_variable() {
  local prompt default val

  prompt="$1"
  default="${2:-}"

  if [ -n "$default" ]; then
    read -rp "$prompt [default: $default]: " val
    val=${val:-$default}
  else
    read -rp "$prompt: " val
  fi

  printf '%s' "$val"
}

create_config_file() {
  local config_file="$TARGET_DIR/config.json"

  mkdir -p "$TARGET_DIR"

  if [ ! -f "$config_file" ]; then
    echo "{}" > "$config_file"
  fi
}

set_config() {
  local key="$1"
  local value="$2"
  local config_file="$TARGET_DIR/config.json"

  jq --arg k "$key" --arg v "$value" \
    'setpath($k | split("."); $v)' \
    "$config_file" > "$config_file.tmp"

  mv "$config_file.tmp" "$config_file"
}

# Create the target script from stdin
create_script() {
  mkdir -p "$TARGET_DIR"
  local target_file="$TARGET_DIR/$SCRIPT_FILENAME.sh"
  cat > "$target_file"
  chmod +x "$target_file"
}

# Ensure a section comment exists in bashrc
ensure_bashrc_section() {
  local marker="$1"
  [ -f "$BASHRC" ] || : > "$BASHRC"
  if ! grep -qxF "$marker" "$BASHRC"; then
    echo "" >> "$BASHRC"
    echo "$marker" >> "$BASHRC"
  fi
}

# Add source line to bashrc under "# Bash scripts"
set_source() {
  local marker="# Bash scripts"
  local source_line="source \$HOME/.bash_scripts/$SCRIPT_FILENAME.sh"

  ensure_bashrc_section "$marker"

  if ! grep -Fxq "$source_line" "$BASHRC"; then
    sed -i "/$(printf '%s' "$marker" | sed 's/[].[^$*\/]/\\&/g')/a $source_line" "$BASHRC"
  fi
}

# Print final summary automatically
echo_message() {
  echo ""
  echo "$SCRIPT_FILENAME installed successfully!"
  if [ "${#SET_VARS[@]}" -gt 0 ]; then
    echo ""
    echo "Configured environment variables:"
    for kv in "${SET_VARS[@]}"; do
      name="${kv%%=*}"
      value="${kv#*=}"
      printf "  %s=%s\n" "$name" "$value"
    done
  fi
  echo ""
  echo "Reload your terminal or run: source ~/.bashrc"
  echo ""
}

# Script

create_script <<'EOF'
#!/bin/bash

# Goto function
goto() {
  local GOTO_PATH="$(jq -r '.goto.path // empty' "$HOME/.bash_scripts/config.json")"
  local CD_MODE="$(jq -r '.goto.mode // empty' "$HOME/.bash_scripts/config.json")"

  # ---- HELP ----
  if [ "$1" = "--help" ]; then
    echo "goto - Jump to named target folders"
    echo
    echo "Usage:"
    echo "  goto <name>                    Jump to a folder inside the configured target directory"
    echo "  goto --add <name> <target>     Create a symlink inside the target directory"
    echo "  goto --config <key>            Read a config value"
    echo "  goto --config <key> <value>    Set a config value"
    echo "  goto --help                    Show this help message"
    echo
    echo "Configuration (stored in ~/.bash_scripts/config.json):"
    echo "  goto.path   => Base target directory"
    echo "  goto.mode   => '-P' or '-L' (Physical directory by default)"
    echo
    echo "Examples:"
    echo "  goto --config path ~/Documents/MyFavoriteFolder"
    echo "  goto --config path ~/.goto_links"
    echo "  goto --config mode -L"
    echo "  goto --add Projects ~/Documents/Code/Projects"
    echo "  goto Projects"
    return 0
  fi
  # ---- END HELP ----

  # ---- CONFIG MODE ----
  if [ "$1" = "--config" ]; then
    if [ -z "${2:-}" ]; then
      echo "Usage: goto --config [key] [value]"
      return 1
    fi

    local key="$2"
    local full_key="goto.$key"

    # Read
    if [ -z "${3:-}" ]; then
      jq -r --arg k "$full_key" '
        try getpath($k | split(".")) // "(not set)"
      ' "$HOME/.bash_scripts/config.json"
      return 0
    fi

    # Write
    jq --arg k "$full_key" --arg v "$3" \
      'setpath($k | split("."); $v)' \
      "$HOME/.bash_scripts/config.json" > "$HOME/.bash_scripts/config.json.tmp"

    mv "$HOME/.bash_scripts/config.json.tmp" "$HOME/.bash_scripts/config.json"

    echo "Set $full_key = $3"
    return 0
  fi
  # ---- END CONFIG MODE ----

  # --- CONFIG ENSURE ----
  if [ -z "$GOTO_PATH" ]; then
    echo "goto.path is not configured."
    echo
    echo "Please set it before using 'goto':"
    echo "  goto --config path <absolute/path/to/folder>"
    echo
    echo "Note:"
    echo "  If you edit the config file manually, paths must be absolute."
    return 1
  fi
  # --- CONFIG ENSURE ----

  # ---- ADD MODE ----
  if [ "$1" = "--add" ]; then
    if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
      echo "Usage: goto --add [name] [target]"
      return 1
    fi

    local name="$2"
    local target="$3"

    mkdir -p "$GOTO_PATH"
    ln -sfn "$target" "$GOTO_PATH/$name"

    echo "Created symlink:"
    echo "  $name -> $target"
    return 0
  fi
  # ---- END ADD MODE ----

  # ---- MAIN GOTO LOGIC ----
  if [ -z "$1" ]; then
    echo "Usage: goto <NAME>"
    echo "Target directory: $GOTO_PATH"
    return 1
  fi

  local target="$GOTO_PATH/$1"

  if [ ! -d "$target" ]; then
    echo "Target not found: $target"
    return 1
  fi

  if [ -n "$CD_MODE" ]; then
    cd "$CD_MODE" "$target" || return 1
  else
    cd -P "$target" || return 1
  fi
}

# Autocomplete for goto
_goto_complete() {
  local GOTO_PATH="$(jq -r '.goto.path // empty' "$HOME/.bash_scripts/config.json")"

  local arg cur
  arg="${COMP_WORDS[1]}"
  cur="${COMP_WORDS[COMP_CWORD]}"

  # Autocomplete second argument for --add

  if [ "$arg" = "--add" ] && [ $COMP_CWORD -eq 3 ]; then
    local -a dirs
    mapfile -t dirs < <(compgen -d -- "$cur")

    # append "/" manually to match cd behavior
    local -a matches=()
    for entry in "${dirs[@]}"; do
      matches+=("$entry/")
    done

    COMPREPLY=( "${matches[@]}" )
    compopt -o nospace 2>/dev/null || true

    return 0
  fi

  # Autocomplete second argument for --config

  if [ "$arg" = "--config" ] && [ $COMP_CWORD -eq 3 ]; then
    local -a dirs
    mapfile -t dirs < <(compgen -d -- "$cur")

    # append "/" manually to match cd behavior
    local -a matches=()
    for entry in "${dirs[@]}"; do
      matches+=("$entry/")
    done

    COMPREPLY=( "${matches[@]}" )
    compopt -o nospace 2>/dev/null || true

    return 0
  fi

  [ -d "$GOTO_PATH" ] || return 0

  # Default autocomplete

  if [[ "$arg" != --* ]] && [ $COMP_CWORD -eq 1 ]; then
    [ -d "$GOTO_PATH" ] || return 0

    local -a items=()
    local entry

    while IFS= read -r entry; do
      items+=("$entry")
    done < <(ls -1A "$GOTO_PATH" 2>/dev/null)

    COMPREPLY=( $(compgen -W "${items[*]}" -- "$cur") )
    return 0
  fi
}

complete -F _goto_complete goto
EOF

# GOTO_PATH=$(prompt_variable "Enter your goto path")

create_config_file
set_source
echo_message

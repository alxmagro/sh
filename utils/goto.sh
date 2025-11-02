#!/bin/bash
#
# Single-file script installer.
#
# Designed by Alexandre Magro (alexandremagro@live.com)

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

# Ensure a section comment exists in bashrc
ensure_section() {
  local marker="$1"
  [ -f "$BASHRC" ] || : > "$BASHRC"
  if ! grep -qxF "$marker" "$BASHRC"; then
    echo "" >> "$BASHRC"
    echo "$marker" >> "$BASHRC"
  fi
}

# Insert or update an environment variable in bashrc
SET_VARS=()
set_var() {
  local name="$1"
  local value="$2"
  local marker="# Bash script variables"
  local export_line="export $name=\"$value\""

  ensure_section "$marker"

  if grep -qE "^[[:space:]]*export[[:space:]]+$name=" "$BASHRC"; then
    sed -i "s|^[[:space:]]*export[[:space:]]\+$name=.*|$export_line|" "$BASHRC"
  else
    sed -i "/$(printf '%s' "$marker" | sed 's/[].[^$*\/]/\\&/g')/a $export_line" "$BASHRC"
  fi

  SET_VARS+=("$name=$value")
}

# Create the target script from stdin
create_script() {
  mkdir -p "$TARGET_DIR"
  local target_file="$TARGET_DIR/$SCRIPT_FILENAME.sh"
  cat > "$target_file"
  chmod +x "$target_file"
}

# Add source line to bashrc under "# Bash scripts"
set_source() {
  local marker="# Bash scripts"
  local source_line="source \$HOME/.bash_scripts/$SCRIPT_FILENAME.sh"

  ensure_section "$marker"

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

GOTO_PATH=$(prompt_variable "Enter your projects folder path" "$HOME/Documents")

create_script <<'EOF'
#!/bin/bash

# Check if GOTO_PATH is defined
if [ -z "$GOTO_PATH" ]; then
  echo "Environment variable GOTO_PATH is not set."
  echo "Please add this line to your ~/.bashrc:"
  echo 'export GOTO_PATH="$HOME/Documents"'
  return 1
fi

# Goto function
goto() {
  if [ -z "$1" ]; then
    echo "Usage: goto <PROJECT_NAME>"
    echo "Projects folder: $GOTO_PATH"
    return 1
  fi

  local target="$GOTO_PATH/$1"
  if [ ! -d "$target" ]; then
    echo "Project not found: $target"
    return 1
  fi

  cd "$target" || return 1
}

# Autocomplete for goto
_goto_complete() {
  local cur projects
  cur="${COMP_WORDS[COMP_CWORD]}"
  [ -d "$GOTO_PATH" ] || return 0
  projects=$(ls -1d "$GOTO_PATH"/*/ 2>/dev/null | xargs -n 1 basename 2>/dev/null || true)
  COMPREPLY=( $(compgen -W "$projects" -- "$cur") )
}

complete -F _goto_complete goto
EOF

set_var "GOTO_PATH" "$GOTO_PATH"
set_source
echo_message

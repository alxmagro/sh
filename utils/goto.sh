#!/bin/bash

# Installation directory for user scripts
TARGET_DIR="$HOME/.bash_scripts"
mkdir -p "$TARGET_DIR"

# User's bashrc file
BASHRC="$HOME/.bashrc"

# Prompt for GOTO_PATH
read -rp "Enter your projects folder path [default: \$HOME/Documents]: " USER_PATH
USER_PATH=${USER_PATH:-"$HOME/Documents"}

# Comment markers
COMMENT_VARS="# Bash script variables"
COMMENT_SCRIPTS="# Bash scripts"

# Add variables section if missing
if ! grep -qxF "$COMMENT_VARS" "$BASHRC"; then
    echo "" >> "$BASHRC"
    echo "$COMMENT_VARS" >> "$BASHRC"
fi

# Add scripts section if missing
if ! grep -qxF "$COMMENT_SCRIPTS" "$BASHRC"; then
    echo "" >> "$BASHRC"
    echo "$COMMENT_SCRIPTS" >> "$BASHRC"
fi

# Export line for GOTO_PATH
EXPORT_LINE="export GOTO_PATH=\"$USER_PATH\""

# Insert or update GOTO_PATH under the variables section
if grep -q "export GOTO_PATH=" "$BASHRC"; then
    sed -i "s|^export GOTO_PATH=.*|$EXPORT_LINE|" "$BASHRC"
else
    sed -i "/$COMMENT_VARS/a $EXPORT_LINE" "$BASHRC"
fi

# Create goto.sh script content
cat > "$TARGET_DIR/goto.sh" <<'EOF'
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

  # if GOTO_PATH doesn't exist or is not a dir, do nothing
  [ -d "$GOTO_PATH" ] || return 0

  # list subdirectories (basename), handle no results gracefully
  projects=$(ls -1d "$GOTO_PATH"/*/ 2>/dev/null | xargs -n 1 basename 2>/dev/null || true)
  COMPREPLY=( $(compgen -W "$projects" -- "$cur") )
}

complete -F _goto_complete goto
EOF

# Make it executable
chmod +x "$TARGET_DIR/goto.sh"

# Source line for bashrc
SOURCE_LINE="source \$HOME/.bash_scripts/goto.sh"

# Insert the source line below the comment if it is not already present
if ! grep -Fxq "$SOURCE_LINE" "$BASHRC"; then
    sed -i "/$COMMENT_SCRIPTS/a $SOURCE_LINE" "$BASHRC"
fi

echo ""
echo "goto.sh installed successfully!"
echo "  GOTO_PATH set to: $USER_PATH"
echo ""
echo "Reload the terminal."

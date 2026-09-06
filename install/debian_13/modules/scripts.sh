#!/bin/bash
# desc: Install helpful new commands

set -e

log 'Copying commands...'

# Install owns this tree: wipe and lay it down fresh so a renamed or dropped
# file never lingers from an earlier run.
rm -rf "$PROJECT_ROOT"
ensure_folder "$PROJECT_ROOT"
cp -r "$SH_ROOT"/src/shared/* "$PROJECT_ROOT/"

# The user owns their config: seed a file only when it is missing.
log 'Seeding config...'
ensure_folder "$CONFIG_ROOT"
for file in "$SH_ROOT"/src/config/*; do
  dest="$CONFIG_ROOT/$(basename "$file")"
  [ -e "$dest" ] || cp "$file" "$dest"
done

append_once "$HOME/.bashrc" 'source ~/.local/share/nikit/init.sh'

#!/bin/bash
#
# Bootstrap for a fresh machine:
#
#   wget -qO - https://raw.githubusercontent.com/alxmagro/nikit/main/get.sh | bash
#
# That opens a picker for the distro and its modules. To run non-interactively:
#
#   wget -qO - .../get.sh | bash -s -- -d debian_13 -m scripts,docker
#
# Unpacks the repo into a temporary folder and hands over to the install.sh
# inside it. Arguments go straight through.

set -eo pipefail

repo="alxmagro/nikit"
ref="main"
src="$(mktemp -d)"
url="https://github.com/$repo/archive/refs/heads/$ref.tar.gz"

trap 'rm -rf "$src"' EXIT

echo "nikit  $repo@$ref"
echo

if command -v curl > /dev/null; then
  curl -fsSL "$url"
else
  wget -qO - "$url"
fi | tar xz -C "$src" --strip-components 1

bash "$src/install.sh" "$@"

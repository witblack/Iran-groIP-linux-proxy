#!/usr/bin/env bash
set -euo pipefail

readonly repository_url='https://github.com/witblack/Iran-groIP-linux-proxy.git'
readonly install_dir='/opt/Iran-groIP-linux-proxy'

if ((EUID != 0)); then
  echo 'Run the quick-install command with sudo.' >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  cat >&2 <<'EOF'
Git is required to download the project. Install it first, then run the quick-install command again.
  Debian/Ubuntu: sudo apt update && sudo apt install git
  Fedora/RHEL:   sudo dnf install git
  Arch Linux:    sudo pacman -S git
  Alpine:        sudo apk add git
EOF
  exit 1
fi

if [[ -e $install_dir ]]; then
  echo "$install_dir already exists. Use its install.sh or remove it before running quick install." >&2
  exit 1
fi

git clone --depth 1 "$repository_url" "$install_dir"
exec "$install_dir/install.sh"

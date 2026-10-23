#!/usr/bin/env bash
set -euo pipefail

readonly install_dir='/opt/Iran-groIP-linux-proxy'
readonly service_name='Iran-groIP-linux-proxy.service'
readonly service_path="/etc/systemd/system/$service_name"

if ((EUID != 0)); then
  echo 'Run this uninstaller as root, for example: sudo ./uninstall.sh' >&2
  exit 1
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ $script_dir != "$install_dir" ]]; then
  echo "This script must be run from $install_dir." >&2
  exit 1
fi

read -r -p "Remove $service_name and $install_dir? This deletes .env and the local IP list. [y/N] " confirm
if [[ ${confirm,,} != 'y' && ${confirm,,} != 'yes' ]]; then
  echo 'Uninstall cancelled.'
  exit 0
fi

systemctl stop "$service_name" >/dev/null 2>&1 || true
systemctl disable "$service_name" >/dev/null 2>&1 || true
rm -f -- "$service_path"
systemctl daemon-reload
rm -rf -- "$install_dir"
echo 'Iran-groIP-linux-proxy has been uninstalled.'

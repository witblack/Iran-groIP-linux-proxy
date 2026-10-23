#!/usr/bin/env bash
set -u

readonly install_dir='/opt/Iran-groIP-linux-proxy'
readonly service_name='Iran-groIP-linux-proxy.service'
readonly service_path="/etc/systemd/system/$service_name"

has_problem=0

show_path_status() {
  local path=$1
  local description=$2

  if [[ -e $path ]]; then
    printf '[OK]      %s: %s\n' "$description" "$path"
  else
    printf '[MISSING] %s: %s\n' "$description" "$path"
    has_problem=1
  fi
}

echo 'Iran-groIP-linux-proxy installation status'
echo '=========================================='
show_path_status "$install_dir" 'Installation directory'
show_path_status "$service_path" 'systemd unit file'

echo
echo 'Installed project files'
echo '-----------------------'
for file in connect-to-us.sh update-iran-ip-list.sh install.sh uninstall.sh check-installation-status.sh service-control.sh iran-ipv4.txt .env; do
  show_path_status "$install_dir/$file" "$file"
done

echo
echo 'systemd service status'
echo '----------------------'
if ! command -v systemctl >/dev/null 2>&1; then
  echo '[UNAVAILABLE] systemctl is not installed.'
  has_problem=1
elif [[ ! -e $service_path ]]; then
  echo '[UNAVAILABLE] The systemd unit file is missing.'
  has_problem=1
else
  if systemctl is-enabled --quiet "$service_name"; then
    echo '[OK]      Enabled at boot: yes'
  else
    echo '[INFO]    Enabled at boot: no'
  fi

  if systemctl is-active --quiet "$service_name"; then
    echo '[OK]      Service power: ON (active)'
  else
    echo '[INFO]    Service power: OFF (inactive or failed)'
  fi
fi

echo
echo 'Configuration checks'
echo '--------------------'
if [[ -f $install_dir/.env ]]; then
  permissions=$(stat -c '%a' "$install_dir/.env" 2>/dev/null || true)
  if [[ $permissions == '600' ]]; then
    echo '[OK]      .env permissions: 600'
  else
    echo "[WARNING] .env permissions: ${permissions:-unknown} (recommended: 600)"
    has_problem=1
  fi
fi

if [[ -s $install_dir/iran-ipv4.txt ]]; then
  cidr_count=$(awk 'END { print NR }' "$install_dir/iran-ipv4.txt")
  echo "[OK]      Iran IPv4 CIDRs: $cidr_count"
fi

echo
if ((has_problem)); then
  echo 'Status: installation needs attention.'
  exit 1
fi

echo 'Status: installation files are present.'

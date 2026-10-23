#!/usr/bin/env bash
set -euo pipefail

readonly install_dir='/opt/Iran-groIP-linux-proxy'
readonly service_name='Iran-groIP-linux-proxy.service'
readonly service_path="/etc/systemd/system/$service_name"

is_yes() {
  [[ ${1,,} == 'y' || ${1,,} == 'yes' ]]
}

print_install_hint() {
  local command_name=$1
  case "$command_name" in
    sshuttle|sshpass|curl)
      cat <<EOF
Install "$command_name" with your distribution package manager, for example:
  Debian/Ubuntu: sudo apt update && sudo apt install $command_name
  Fedora/RHEL:   sudo dnf install $command_name
  Arch Linux:    sudo pacman -S $command_name
  Alpine:        sudo apk add $command_name
EOF
      ;;
    systemctl)
      cat <<'EOF'
This installer requires a Linux distribution that uses systemd. Install or boot
into a systemd-based environment, then run the installer again.
EOF
      ;;
  esac
}

missing_dependencies=()
for dependency in bash curl sshuttle sshpass systemctl; do
  command -v "$dependency" >/dev/null 2>&1 || missing_dependencies+=("$dependency")
done

if ((${#missing_dependencies[@]})); then
  echo 'Required dependencies are missing:' >&2
  for dependency in "${missing_dependencies[@]}"; do
    echo "- $dependency" >&2
    print_install_hint "$dependency" >&2
  done
  exit 1
fi

if ((EUID != 0)); then
  echo 'Run this installer as root, for example: sudo ./install.sh' >&2
  exit 1
fi

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ $source_dir != "$install_dir" ]]; then
  if [[ -e $install_dir ]]; then
    echo "$install_dir already exists. Refusing to overwrite it." >&2
    exit 1
  fi

  mkdir -p /opt
  mv -- "$source_dir" "$install_dir"
  exec "$install_dir/install.sh"
fi

read -r -p 'Enable this service to start automatically at boot? [y/N] ' enable_at_boot
read -r -p 'SSH server host or IP address: ' ssh_host
read -r -p 'SSH server port [22]: ' ssh_port
read -r -p 'SSH username: ' ssh_username
read -r -s -p 'SSH password: ' ssh_password
echo
read -r -p 'Reconnect delay in seconds [5]: ' reconnect_delay_seconds

ssh_port=${ssh_port:-22}
reconnect_delay_seconds=${reconnect_delay_seconds:-5}
for value_name in ssh_host ssh_port ssh_username ssh_password reconnect_delay_seconds; do
  if [[ -z ${!value_name} ]]; then
    echo "${value_name#ssh_} cannot be empty." >&2
    exit 1
  fi
done

if [[ ! $ssh_port =~ ^[1-9][0-9]{0,4}$ ]] || ((ssh_port > 65535)); then
  echo 'SSH port must be a number between 1 and 65535.' >&2
  exit 1
fi

if [[ ! $reconnect_delay_seconds =~ ^[1-9][0-9]*$ ]]; then
  echo 'Reconnect delay must be a positive whole number of seconds.' >&2
  exit 1
fi

umask 077
{
  printf 'SSH_USERNAME=%q\n' "$ssh_username"
  printf 'SSH_PASSWORD=%q\n' "$ssh_password"
  printf 'SSH_HOST=%q\n' "$ssh_host"
  printf 'SSH_PORT=%q\n' "$ssh_port"
  printf 'RECONNECT_DELAY_SECONDS=%q\n' "$reconnect_delay_seconds"
} > "$install_dir/.env"
chmod 600 "$install_dir/.env"

cat > "$service_path" <<EOF
[Unit]
Description=Iran-groIP-linux-proxy SSHuttle split tunnel
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
WorkingDirectory=$install_dir
ExecStart=$install_dir/connect-to-us.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
if is_yes "$enable_at_boot"; then
  systemctl enable "$service_name"
else
  systemctl disable "$service_name" >/dev/null 2>&1 || true
fi

read -r -p 'Start the service now? [y/N] ' start_now
if is_yes "$start_now"; then
  systemctl start "$service_name"
  systemctl --no-pager --full status "$service_name"
else
  echo "Installation complete. Start it later with: sudo systemctl start $service_name"
fi

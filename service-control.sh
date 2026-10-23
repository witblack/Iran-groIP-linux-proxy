#!/usr/bin/env bash
set -euo pipefail

readonly service_name='Iran-groIP-linux-proxy.service'

usage() {
  cat <<EOF
Usage: $0 {on|off|status}

  on      Start the service now.
  off     Stop the service now.
  status  Show whether the service is ON or OFF and display its systemd status.
EOF
}

if ! command -v systemctl >/dev/null 2>&1; then
  echo 'systemctl is required to control this service.' >&2
  exit 1
fi

case ${1:-} in
  on)
    if ((EUID != 0)); then
      echo 'Run this command as root: sudo ./service-control.sh on' >&2
      exit 1
    fi
    systemctl start "$service_name"
    echo 'Service power: ON'
    ;;
  off)
    if ((EUID != 0)); then
      echo 'Run this command as root: sudo ./service-control.sh off' >&2
      exit 1
    fi
    systemctl stop "$service_name"
    echo 'Service power: OFF'
    ;;
  status)
    if systemctl is-active --quiet "$service_name"; then
      echo 'Service power: ON (active)'
    else
      echo 'Service power: OFF (inactive or failed)'
    fi
    systemctl --no-pager --full status "$service_name" || true
    ;;
  -h|--help|help|'')
    usage
    ;;
  *)
    echo "Unknown action: $1" >&2
    usage >&2
    exit 1
    ;;
esac

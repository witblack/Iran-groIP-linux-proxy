#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
iran_cidrs="$script_dir/iran-ipv4.txt"
env_file="$script_dir/.env"

if [[ ! -f $env_file ]]; then
  echo "Connection settings are missing. Create $env_file first." >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$env_file"

for setting in SSH_USERNAME SSH_PASSWORD SSH_HOST SSH_PORT RECONNECT_DELAY_SECONDS; do
  if [[ -z ${!setting:-} ]]; then
    echo "$setting is missing in $env_file." >&2
    exit 1
  fi
done

if [[ ! $SSH_PORT =~ ^[1-9][0-9]{0,4}$ ]] || ((SSH_PORT > 65535)); then
  echo 'SSH_PORT must be a number between 1 and 65535.' >&2
  exit 1
fi

if [[ ! $RECONNECT_DELAY_SECONDS =~ ^[1-9][0-9]*$ ]]; then
  echo 'RECONNECT_DELAY_SECONDS must be a positive integer.' >&2
  exit 1
fi

if [[ ! -s $iran_cidrs ]]; then
  echo "Iran IP list is missing. Run $script_dir/update-iran-ip-list.sh first." >&2
  exit 1
fi

trap 'exit 0' INT TERM

while true; do
  if sshpass -p "$SSH_PASSWORD" sshuttle --dns \
    -x 0.0.0.0/8 -x 10.0.0.0/8 -x 100.64.0.0/10 -x 127.0.0.0/8 \
    -x 169.254.0.0/16 -x 172.16.0.0/12 -x 192.168.0.0/16 \
    -x 198.18.0.0/15 -x 224.0.0.0/4 -X "$iran_cidrs" \
    -r "$SSH_USERNAME@$SSH_HOST:$SSH_PORT" 0.0.0.0/0; then
    echo 'SSHuttle stopped. Reconnecting soon...' >&2
  else
    echo 'SSHuttle connection failed or was interrupted. Retrying soon...' >&2
  fi

  sleep "$RECONNECT_DELAY_SECONDS"
done

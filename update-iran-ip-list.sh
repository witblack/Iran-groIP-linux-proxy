#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
list_file="$script_dir/iran-ipv4.txt"
source_url='https://raw.githubusercontent.com/farshidmousavii/iran-ip-ranges/main/dist/raw/ipv4.txt'
tmp_file=$(mktemp "$script_dir/.iran-ipv4.txt.XXXXXX")
clean_file="$tmp_file.clean"
trap 'rm -f "$tmp_file" "$clean_file"' EXIT

curl --fail --silent --show-error --location "$source_url" -o "$tmp_file"
awk '/^[0-9.]+\/[0-9]+$/ { print }' "$tmp_file" > "$clean_file"

if [[ ! -s $clean_file ]]; then
  echo 'The downloaded Iran IP list contains no valid IPv4 CIDRs.' >&2
  exit 1
fi

mv -- "$clean_file" "$list_file"
echo "Updated $list_file ($(wc -l < "$list_file") IPv4 CIDRs)."

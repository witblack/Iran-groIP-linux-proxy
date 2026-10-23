# Iran-groIP-linux-proxy

This project routes Internet traffic through an SSHuttle connection while keeping the following destinations outside the proxy:

## Quick install

Copy and run this single command in a Linux terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/witblack/Iran-groIP-linux-proxy/main/quick-install.sh | sudo bash
```

It downloads the small bootstrap script directly from GitHub, clones this project into `/opt/Iran-groIP-linux-proxy`, and starts `install.sh`. The installer reads its interactive questions from your terminal, then checks the required packages and asks for all connection settings.

- Iranian IPv4 ranges, loaded from the local `iran-ipv4.txt` file
- `localhost` and `127.0.0.0/8`
- Private networks: `10.0.0.0/8`, `172.16.0.0/12`, and `192.168.0.0/16`
- Local or reserved ranges such as link-local, CGNAT, and multicast networks

## Project files

- `connect-to-us.sh` — starts the SSHuttle connection.
- `update-iran-ip-list.sh` — downloads and safely updates the local Iran IPv4 list.
- `iran-ipv4.txt` — local Iran IPv4 CIDR list used by the connection script.
- `.env` — your real SSH connection settings. This file contains sensitive data.
- `.env.example` — a safe configuration template with placeholders only.

## Requirements

Install these commands before using the scripts:

```bash
sshuttle
sshpass
curl
```

## Configure the SSH connection

If `.env` does not exist yet, create it from the example file:

```bash
cp .env.example .env
chmod 600 .env
```

Open `.env` and provide your SSH server details:

```env
SSH_USERNAME='your-ssh-username'
SSH_PASSWORD='your-ssh-password'
SSH_HOST='your-server-host-or-ip'
SSH_PORT='22'
RECONNECT_DELAY_SECONDS='5'
```

All five variables are required. SSH usually uses port `22`; replace it if your server uses a different port. `RECONNECT_DELAY_SECONDS` is the positive number of seconds to wait before retrying after a failed or closed SSHuttle connection.

## Usage

Update the local Iran IP list before the first connection and whenever you want to refresh it:

```bash
./update-iran-ip-list.sh
```

Example output:

```text
Updated /path/to/project/iran-ipv4.txt (1805 IPv4 CIDRs).
```

Start the split-tunnel connection:

```bash
./connect-to-us.sh
```

`connect-to-us.sh` never downloads an IP list. It only reads the local `iran-ipv4.txt` file. If that file is missing or empty, the script stops and tells you to run the update script first.

If SSHuttle disconnects for any reason, `connect-to-us.sh` waits for `RECONNECT_DELAY_SECONDS` and then attempts to reconnect. For example, set `RECONNECT_DELAY_SECONDS='10'` to wait ten seconds between connection attempts.

## Install as a systemd service

Run the installer as root from the project directory:

```bash
sudo ./install.sh
```

Before making any changes, the installer checks for `bash`, `curl`, `sshuttle`, `sshpass`, and `systemctl`. If something is missing, it stops and displays package-manager commands for installing it.

The installer moves the whole project to `/opt/Iran-groIP-linux-proxy` when necessary. It then asks whether the service should start automatically at boot, asks for the SSH host, port, username, password, and reconnect delay, and creates `/opt/Iran-groIP-linux-proxy/.env` with owner-only permissions. Finally, it creates the `Iran-groIP-linux-proxy.service` systemd unit.

The final installer prompt asks whether to start the service immediately. You can also control it manually:

```bash
sudo systemctl start Iran-groIP-linux-proxy.service
sudo systemctl stop Iran-groIP-linux-proxy.service
sudo systemctl status Iran-groIP-linux-proxy.service
```

To remove the service and the installed project, run this command from the installed directory:

```bash
cd /opt/Iran-groIP-linux-proxy
sudo ./uninstall.sh
```

The uninstaller asks for confirmation, stops and disables the service, removes its systemd unit, and deletes `/opt/Iran-groIP-linux-proxy` including `.env` and the local IP list.

## Check installation status

After installation, run the read-only status checker to see whether the installation directory, expected project files, `.env`, IP list, and systemd unit file exist. It also reports whether the service is enabled at boot or currently active without printing any SSH credentials:

```bash
/opt/Iran-groIP-linux-proxy/check-installation-status.sh
```

The script exits with status code `0` when all required installation files are present, or `1` when it finds a missing file, directory, systemd unit, unavailable `systemctl`, or insecure `.env` permissions.

## Updating the Iran IP list

`update-iran-ip-list.sh` downloads the IPv4 CIDR list from the public `farshidmousavii/iran-ip-ranges` GitHub repository, removes invalid lines, and atomically replaces `iran-ipv4.txt`. If the download or validation fails, the existing list remains unchanged.

For example, this cron entry updates the list every Sunday at 03:00:

```cron
0 3 * * 0 /path/to/project/update-iran-ip-list.sh
```

Replace `/path/to/project` with this project's actual absolute path.

## Security notes

- `.env` contains an SSH password. Do not share it or commit it to a public repository.
- Share `.env.example` instead of `.env`.
- Review the server host and connection settings in `.env` before running the connection script.
- The Iran list is based on IP CIDRs, not domain names. Newly allocated ranges will be included after the next update.

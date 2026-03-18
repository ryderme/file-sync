# file-sync

A command-line tool that automatically renames and syncs local files to a VPS.

**Use case**: Screenshots, documents, and exported files on Mac → unified renaming → auto-upload to a remote server. Supports multiple Macs simultaneously.

## Features

- Renames files using modification time as a timestamp (`20260318_143022.png`), preventing naming conflicts across multiple machines
- Tracks uploaded files and only uploads new ones — no duplicate transfers
- Supports file type filtering; leave empty to sync all files
- Supports both manual sync and auto-watch modes
- Supports running persistently via `launchd` on Mac login
- All configuration is externalized — each machine has its own config

## Prerequisites

- macOS (uses macOS `stat` syntax)
- SSH key configured for passwordless login to VPS
- Auto-watch mode requires [fswatch](https://github.com/emcee-software/fswatch): `brew install fswatch`
- Upload requires `rsync` and `ssh` (included with macOS by default)

## Installation

```bash
git clone git@github.com:ryderme/file-sync.git
cd file-sync
chmod +x file-sync.sh
```

Add to PATH (append to `~/.zshrc`):

```bash
export PATH="$PATH:$HOME/github/file-sync"
```

Then run `source ~/.zshrc` to apply.

## Configuration

```bash
cp file-sync.conf.example file-sync.conf
```

Edit `file-sync.conf` in the project directory:

```bash
VPS_HOST="your-vps-ip"          # Required: VPS IP or hostname
VPS_USER="ubuntu"                # VPS login user, default: ubuntu
VPS_PATH="~/uploads"             # Target directory on VPS
SSH_KEY="$HOME/.ssh/id_ed25519"  # SSH private key path
LOCAL_DIR="$HOME/uploads"        # Local directory to watch
FILE_TYPES=""                    # Leave empty for all files, or e.g. "png,jpg,pdf,md"
```

The script first looks for `file-sync.conf` in the project directory; if not found, it falls back to `~/.file-sync.conf`.

`file-sync.conf` is gitignored and will not be committed, so each machine can have its own config.

## Usage

Drop files into the local directory (default `~/uploads/`), then:

```bash
# Manual sync: rename + upload new files
file-sync.sh

# Auto-watch: sync automatically when new files are added
file-sync.sh watch
```

Default behavior:

- Both manual and auto-watch modes rename files before uploading
- Uploaded files are recorded in `LOCAL_DIR/.uploaded`
- Remote directory is created automatically if it doesn't exist
- Auto-watch only processes files in the top level of `LOCAL_DIR`, not subdirectories

## Auto-start on Login

Use macOS `launchd` to keep `watch` mode running in the background. Full setup instructions:

- `docs/mac-launchd-setup.md`

Common management commands:

```bash
# Reload service
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.ryderme.file-sync.plist 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.ryderme.file-sync.plist
launchctl kickstart -k gui/$(id -u)/com.ryderme.file-sync

# Check status
launchctl print gui/$(id -u)/com.ryderme.file-sync

# View logs
tail -f ~/Library/Logs/file-sync.log
```

## Multiple Macs

Each machine clones independently and has its own `file-sync.conf`, all uploading to the same directory on the VPS. Timestamp-based naming prevents conflicts between machines.

```
Mac 1 ──┐
         ├── file-sync ──→ VPS ~/uploads/
Mac 2 ──┘
```

## Troubleshooting

- **Config not applied**: the script reads `file-sync.conf` in the project directory first, then falls back to `~/.file-sync.conf`
- **Watch running but nothing happens**: check `launchctl print gui/$(id -u)/com.ryderme.file-sync` shows `state = running`
- **Files not uploading**: check `~/Library/Logs/file-sync.log`
- **Remote path**: `VPS_PATH="~/uploads"` expands to `/home/<user>/uploads` on the server

## File Reference

| File | Description |
|------|-------------|
| `file-sync.sh` | Main script |
| `file-sync.conf.example` | Configuration template |
| `file-sync.conf` | Local config (gitignored, create manually) |
| `docs/mac-launchd-setup.md` | Mac `launchd` auto-start guide |
| `~/uploads/.uploaded` | Upload record (auto-maintained) |

## License

MIT

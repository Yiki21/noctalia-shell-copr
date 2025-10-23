# noctalia-shell COPR automation

This repository maintains COPR specs for `noctalia-shell` and its dependencies including `quickshell`, `matugen`, and `cliphist`.

## What's automated
- Each package directory contains an `update.sh` script that:
  - Checks GitHub for the latest release version
  - Updates the version in the spec file
  - Commits changes if a new version is detected
- A scheduled GitHub Action runs every 12 hours to:
  - Execute all `update.sh` scripts
  - Push changes to the repository
  - Trigger COPR builds via webhook

## GitHub Action schedule
The workflow `.github/workflows/update.yml` runs every 12 hours and on manual dispatch.

To have it trigger COPR automatically on schedule, add a repository secret `COPR_WEBHOOK_URL` set to your COPR custom webhook URL and add a curl step in the workflow to POST `{}` to it. If you prefer, you can also configure a GitHub→COPR repository webhook and trigger builds by pushing changes.

## Package tracking

Each package has its own update script:
- `quickshell/update.sh` - Tracks [quickshell-mirror/quickshell](https://github.com/quickshell-mirror/quickshell)
- `matugen/update.sh` - Tracks [InioX/matugen](https://github.com/InioX/matugen)
- `cliphist/update.sh` - Tracks [sentriz/cliphist](https://github.com/sentriz/cliphist)
- `noctalia-shell/update.sh` - Tracks [noctalia-dev/noctalia-shell](https://github.com/noctalia-dev/noctalia-shell)

## Setup

### Configure COPR webhook
To enable automatic COPR builds:

1. In COPR, create a custom webhook for your project and copy the URL
2. In GitHub, add a repository secret `COPR_WEBHOOK_URL` with that URL
3. The workflow will automatically trigger builds when versions are updated

### Manual testing
You can test update scripts locally:

```bash
cd quickshell
bash update.sh
```

## User setup after install
This package installs the config under `/usr/share/quickshell/noctalia-shell`.

Initialize your user config:

```bash
# Recommended: symlink so updates flow automatically
noctalia-shell

# Alternatively, copy into your home (then update manually later)
noctalia-shell --copy

# Overwrite existing config
noctalia-shell --force
```

Configs will appear at `~/.config/quickshell/noctalia-shell`.

## Manual run
- Go to GitHub → Actions → “Trigger COPR build” → Run workflow.

## Troubleshooting
- If COPR didn’t start building, verify your webhook path (either the custom webhook URL used by the Action, or the repository webhook) and check delivery logs in both GitHub and COPR.

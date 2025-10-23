# noctalia-shell COPR automation

This repo maintains the COPR spec for `noctalia-shell`. The spec now fetches the upstream latest release asset directly, so you don't need a commit-bump script.

## What’s automated
- Spec uses `Source0: .../releases/latest/download/noctalia-latest.tar.gz` so builds always use the latest upstream release.
- A scheduled GitHub Action can trigger COPR to build via a custom webhook (recommended), or you can trigger builds manually in COPR.

## GitHub Action schedule
The workflow `.github/workflows/update.yml` runs every 6 hours and on manual dispatch.

To have it trigger COPR automatically on schedule, add a repository secret `COPR_WEBHOOK_URL` set to your COPR custom webhook URL and add a curl step in the workflow to POST `{}` to it. If you prefer, you can also configure a GitHub→COPR repository webhook and trigger builds by pushing changes.

## Configure COPR triggering options
You have two options:

1) Scheduled Action → COPR custom webhook (recommended)
   - In COPR, create a custom webhook for your project and copy the URL.
   - In GitHub, add a repository secret `COPR_WEBHOOK_URL` with that URL.
   - In `.github/workflows/update.yml`, add a step to POST `{}` to `$COPR_WEBHOOK_URL`.

2) GitHub repository → COPR repository webhook (push events)
   - In COPR, set up a GitHub repository webhook.
   - In GitHub, add the webhook under Settings → Webhooks (payload URL from COPR, content type `application/json`).
   - Trigger builds by pushing to this repo (manual or with your own automation).

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

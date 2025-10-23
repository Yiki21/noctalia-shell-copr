#!/usr/bin/env bash
set -euo pipefail

# update.sh
# - Bump Version in .copr/noctalia-shell.spec from upstream latest tag/release
# - Watch specific upstream packaging files; if they changed since last run, trigger COPR build via webhook
#
# Env vars (optional):
#   UPSTREAM_REPO        default: noctalia-dev/noctalia-shell
#   SPEC_PATH            default: .copr/noctalia-shell.spec
#   STATE_FILE           default: .github/deps_state.json
#   COPR_WEBHOOK_URL     default: (unset)  -> if set, POST {} to trigger build when changes detected
#   GITHUB_TOKEN         default: (unset)  -> used to raise GitHub API rate limits
#   NO_GIT               default: 0       -> set to 1 to skip git add/commit/push
#   PUSH                 default: 0       -> set to 1 to git push after commit (when credentials configured)
#
# Dependencies: curl, jq, sed, perl, git (optional for committing)

UPSTREAM_REPO=${UPSTREAM_REPO:-noctalia-dev/noctalia-shell}
SPEC_PATH=${SPEC_PATH:-.copr/noctalia-shell.spec}
STATE_FILE=${STATE_FILE:-.github/deps_state.json}
COPR_WEBHOOK_URL=${COPR_WEBHOOK_URL:-}
NO_GIT=${NO_GIT:-0}
PUSH=${PUSH:-0}

gh_api() {
  local url=$1
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" "$url"
  else
    curl -fsSL -H "Accept: application/vnd.github+json" "$url"
  fi
}

require_cmd() {
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 || { echo "Missing dependency: $c" >&2; exit 2; }
  done
}

main() {
  require_cmd curl jq sed perl

  local changed_any=0

  bump_spec_version || true
  if [[ ${BUMP_CHANGED:-0} -eq 1 ]]; then
    changed_any=1
  fi

  watch_dependencies || true
  if [[ ${DEPS_CHANGED:-0} -eq 1 ]]; then
    changed_any=1
  fi

  git_ops || true

  # Do NOT trigger webhook here by default; leave the decision to CI.
  # If COPR_WEBHOOK_URL is set explicitly in env, allow triggering from local runs.
  if [[ -n "${COPR_WEBHOOK_URL:-}" ]]; then
    trigger_webhook_if_needed "$changed_any"
  fi

  # Expose result to GitHub Actions if available
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "changed=$changed_any" >>"$GITHUB_OUTPUT"
    echo "spec_changed=${BUMP_CHANGED:-0}" >>"$GITHUB_OUTPUT"
    echo "deps_changed=${DEPS_CHANGED:-0}" >>"$GITHUB_OUTPUT"
  fi

  # Also print a simple summary for local runs
  echo "RESULT changed=$changed_any spec_changed=${BUMP_CHANGED:-0} deps_changed=${DEPS_CHANGED:-0}"
}

bump_spec_version() {
  if [[ ! -f "$SPEC_PATH" ]]; then
    echo "Spec not found: $SPEC_PATH" >&2
    return 0
  fi

  echo "[version] Determining latest upstream version for $UPSTREAM_REPO..."
  local latest_tag latest_ver current_ver

  latest_tag=$(gh_api "https://api.github.com/repos/${UPSTREAM_REPO}/releases/latest" | jq -r '.tag_name // empty' || true)
  if [[ -z "$latest_tag" || "$latest_tag" == null ]]; then
    latest_tag=$(gh_api "https://api.github.com/repos/${UPSTREAM_REPO}/tags?per_page=1" | jq -r '.[0].name // empty' || true)
  fi
  if [[ -z "$latest_tag" || "$latest_tag" == null ]]; then
    echo "[version] No upstream tag found; skip." >&2
    BUMP_CHANGED=0
    return 0
  fi

  latest_ver=${latest_tag#v}
  latest_ver=${latest_ver//- /~}
  latest_ver=${latest_ver//-/~}

  current_ver=$(sed -n 's/^Version:\s\+\(.*\)$/\1/p' "$SPEC_PATH" | head -1)
  if [[ -z "$current_ver" ]]; then
    echo "[version] Could not read current Version from $SPEC_PATH; skip." >&2
    BUMP_CHANGED=0
    return 0
  fi

  if [[ "$current_ver" == "$latest_ver" ]]; then
    echo "[version] Already up-to-date ($current_ver)."
    BUMP_CHANGED=0
    return 0
  fi

  echo "[version] Bumping Version: $current_ver -> $latest_ver"
  perl -0777 -pe "s/(^Version:\s*)\Q$current_ver\E\s*$/\$1$latest_ver\n/m" -i "$SPEC_PATH"
  BUMP_CHANGED=1
}

watch_dependencies() {
  echo "[deps] Checking watched files in external packaging repos..."
  mkdir -p "$(dirname "$STATE_FILE")"
  if [[ ! -f "$STATE_FILE" ]]; then
    echo '{}' >"$STATE_FILE"
  fi

  local -a items=(
    # repo|path
    "ErrorNoInternet/rpm-packages|.copr/Makefile"
    "ErrorNoInternet/rpm-packages|cliphist/bundle_go_deps_for_rpm.sh"
    "ErrorNoInternet/rpm-packages|cliphist/cliphist.spec"
    "ErrorNoInternet/rpm-packages|quickshell/quickshell.spec"
    "BrycensRanch/gpu-screen-recorder-git-copr|gpu-screen-recorder.spec"
    "solopasha/hyprlandRPM|matugen/matugen.spec"
  )

  local any_changed=0
  local first_run=0
  if [[ $(jq -r 'keys | length' "$STATE_FILE") -eq 0 ]]; then
    first_run=1
  fi

  for entry in "${items[@]}"; do
    local repo="${entry%%|*}"
    local path="${entry#*|}"
    local key="${repo}|${path}"

    # latest commit touching file
    local commit_json commit_sha commit_date
    commit_json=$(gh_api "https://api.github.com/repos/${repo}/commits?path=$(python3 - <<EOF
import urllib.parse,sys
print(urllib.parse.quote(sys.argv[1]))
EOF
"$path")&per_page=1") || commit_json=""
    commit_sha=$(echo "$commit_json" | jq -r '.[0].sha // empty' || true)
    commit_date=$(echo "$commit_json" | jq -r '.[0].commit.committer.date // empty' || true)

    if [[ -z "$commit_sha" ]]; then
      echo "[deps] WARN: Cannot resolve latest commit for $repo:$path" >&2
      continue
    fi

    local prev_sha
    prev_sha=$(jq -r --arg k "$key" '.[$k].sha // empty' "$STATE_FILE" || true)

    if [[ "$prev_sha" != "$commit_sha" ]]; then
      if [[ $first_run -eq 1 ]]; then
        echo "[deps] First run baseline for $key -> $commit_sha @ $commit_date"
      else
        echo "[deps] Detected change in $key: $prev_sha -> $commit_sha (@ $commit_date)"
        any_changed=1
      fi
      # update state
      tmpfile=$(mktemp)
      jq --arg k "$key" --arg s "$commit_sha" --arg d "${commit_date:-}" \
        '. as $root | ($root[$k] // {}) as $n | $root + {($k): ($n + {sha: $s, date: $d})}' \
        "$STATE_FILE" >"$tmpfile"
      mv "$tmpfile" "$STATE_FILE"
    fi
  done

  if [[ $any_changed -eq 1 ]]; then
    DEPS_CHANGED=1
  else
    DEPS_CHANGED=0
    echo "[deps] No watched file changes detected."
  fi
}

git_ops() {
  if [[ ${NO_GIT} -eq 1 ]]; then
    return 0
  fi
  if ! command -v git >/dev/null 2>&1; then
    return 0
  fi

  # Only commit if there are changes
  if [[ -n $(git status --porcelain 2>/dev/null || true) ]]; then
    git add "$SPEC_PATH" "$STATE_FILE" 2>/dev/null || true
    git commit -m "automation: update spec version and dependency state" || true
    if [[ ${PUSH} -eq 1 ]]; then
      git pull --rebase || true
      git push || true
    fi
  fi
}

trigger_webhook_if_needed() {
  local changed_any=$1
  if [[ $changed_any -ne 1 ]]; then
    echo "[webhook] No changes to trigger."
    return 0
  fi
  if [[ -z "$COPR_WEBHOOK_URL" ]]; then
    echo "[webhook] COPR_WEBHOOK_URL not set; skipping."
    return 0
  fi
  echo "[webhook] Triggering COPR rebuild via custom webhook..."
  curl -fsSL -X POST -H 'Content-Type: application/json' -d '{}' "$COPR_WEBHOOK_URL" && echo "[webhook] Triggered"
}

main "$@"

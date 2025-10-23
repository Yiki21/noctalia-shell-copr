#!/usr/bin/env bash
set -euxo pipefail

SPEC=".copr/noctalia-shell.spec"
REPO="noctalia-dev/noctalia-shell"

NEW_COMMIT=$(curl -s -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$REPO/commits/main" | jq -r .sha)

OLD_COMMIT=$(grep '%global commit0' "$SPEC" | awk '{print $3}')

if [[ "$NEW_COMMIT" == "$OLD_COMMIT" ]]; then
    echo "✅ Already up to date: $NEW_COMMIT"
    exit 0
fi

sed -i "s/^%global commit0.*/%global commit0 $NEW_COMMIT/" "$SPEC"

SHORT_COMMIT=$(echo "$NEW_COMMIT" | cut -c1-7)
BUMPVER=$(grep '%global bumpver' "$SPEC" | awk '{print $3}')
NEW_BUMPVER=$((BUMPVER + 1))
sed -i "s/^%global bumpver.*/%global bumpver $NEW_BUMPVER/" "$SPEC"

VERSION=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | jq -r .tag_name | sed 's/^v//')
sed -i "s/^Version:.*/Version:        ${VERSION}^${NEW_BUMPVER}.git${SHORT_COMMIT}/" "$SPEC"

git add "$SPEC"
git commit -m "Update to version ${VERSION}+${SHORT_COMMIT}"
git push https://github-actions:${{ secrets.GITHUB_TOKEN }}@github.com/Yiki21/noctalia-shell-copr.git

echo "✅ Spec updated to commit $NEW_COMMIT, version ${VERSION}^${NEW_BUMPVER}.git${SHORT_COMMIT}"

#!/usr/bin/env bash
set -euo pipefail

REPO="noctalia-dev/noctalia-shell"
SPEC=".copr/noctalia-shell.spec"
WORKDIR="$(dirname "$(realpath "$0")")"

cd "$WORKDIR"

VERSION=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" \
    | jq -r .tag_name | sed 's/^v//')

if [[ -z "$VERSION" || "$VERSION" == "null" ]]; then
    echo "❌ Can Not Fetch Latest Version"
    exit 1
fi

echo "📦 Latest Version: $VERSION"

if grep -q "Version:[[:space:]]*${VERSION}" "$SPEC"; then
    echo "✅ On Latest Version $VERSION"
    exit 0
fi

TARBALL="noctalia-shell-${VERSION}.tar.gz"
wget -q "https://github.com/${REPO}/archive/refs/tags/v${VERSION}.tar.gz" -O "$TARBALL"

sed -i "s/^Version:.*/Version:        ${VERSION}/" "$SPEC"
sed -i "s|^Source0:.*|Source0:        ${TARBALL}|" "$SPEC"

git add "$SPEC" "$TARBALL"
git commit -m "Update to version ${VERSION}" || true
git push

echo "✅ Updated to Version $VERSION"

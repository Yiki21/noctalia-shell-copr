#!/bin/bash
set -euo pipefail

SPEC_FILE="matugen.spec"
REPO="InioX/matugen"

# Get the latest version from GitHub releases
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    LATEST_VERSION=$(curl -sfL -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${REPO}/releases/latest" | jq -r '.tag_name' | sed 's/^v//')
else
    LATEST_VERSION=$(curl -sfL "https://api.github.com/repos/${REPO}/releases/latest" | jq -r '.tag_name' | sed 's/^v//')
fi

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "null" ]; then
    echo "Failed to fetch latest version for ${REPO}"
    exit 1
fi

# Get current version from spec file
CURRENT_VERSION=$(grep "^Version:" "${SPEC_FILE}" | awk '{print $NF}' | head -n1)

echo "Current version: ${CURRENT_VERSION}"
echo "Latest version: ${LATEST_VERSION}"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "Already at latest version"
    exit 0
fi

###############################################
# 1. Make vendor tarball
###############################################

TMPDIR=$(mktemp -d)
cd "$TMPDIR"
curl -sL "https://github.com/${REPO}/archive/refs/tags/v${LATEST_VERSION}.tar.gz" \
    -o source.tar.gz

tar -xf source.tar.gz
SRCDIR="matugen-${LATEST_VERSION}"
cd "$SRCDIR"

cargo vendor --locked

TARBALL="matugen-${LATEST_VERSION}-vendor.tar.gz"
tar -czf "$TARBALL" vendor

mv "$TARBALL" "$OLDPWD"
cd "$OLDPWD"

###############################################
# 2. Update spec Version
###############################################

# Update version in spec file
sed -i "s/^Version:\s*.*/Version:        ${LATEST_VERSION}/" "${SPEC_FILE}"

echo "Updated ${SPEC_FILE} to version ${LATEST_VERSION}"
echo "Generated vendor tarball: ${VENDOR_TARBALL}"

###############################################
# 3. Commit changes and tag
###############################################

git add "${SPEC_FILE}"
git add "$VENDOR_TARBALL"
git commit -m "matugen: update to ${LATEST_VERSION}" || true
git tag -f "matugen-v${LATEST_VERSION}"
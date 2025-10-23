#!/bin/bash
set -euo pipefail

SPEC_FILE="noctalia-shell.spec"
REPO="noctalia-dev/noctalia-shell"

# Get the latest version from GitHub releases
LATEST_VERSION=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | jq -r '.tag_name' | sed 's/^v//')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "null" ]; then
    echo "Failed to fetch latest version for ${REPO}"
    exit 1
fi

# Get current version from spec file
CURRENT_VERSION=$(rpmspec -q --qf "%{version}\n" "${SPEC_FILE}" | head -n1)

echo "Current version: ${CURRENT_VERSION}"
echo "Latest version: ${LATEST_VERSION}"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "Already at latest version"
    exit 0
fi

# Update version in spec file
sed -i "s/^Version:\s*.*/Version:\t\t${LATEST_VERSION}/" "${SPEC_FILE}"

echo "Updated ${SPEC_FILE} to version ${LATEST_VERSION}"

# Commit changes
git add "${SPEC_FILE}"
git commit -m "noctalia-shell: update to ${LATEST_VERSION}" || true

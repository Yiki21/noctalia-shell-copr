#!/bin/bash
set -euo pipefail

SPEC_FILE="cliphist.spec"
REPO="sentriz/cliphist"

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
CURRENT_VERSION=$(rpmspec -q --qf "%{version}\n" "${SPEC_FILE}" 2>/dev/null | head -n1)

echo "Current version: ${CURRENT_VERSION}"
echo "Latest version: ${LATEST_VERSION}"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "Already at latest version"
    exit 0
fi

# Update version in spec file
sed -i "s/^Version:\s*.*/Version:                ${LATEST_VERSION}/" "${SPEC_FILE}"

echo "Updated ${SPEC_FILE} to version ${LATEST_VERSION}"

# Generate vendor tarball
# The bundle_go_deps_for_rpm.sh script will automatically read the version from the spec file
echo "Generating vendor tarball..."
./bundle_go_deps_for_rpm.sh "${SPEC_FILE}"

if [ -f "vendor-${LATEST_VERSION}.tar.gz" ]; then
    echo "Successfully generated vendor-${LATEST_VERSION}.tar.gz"
    # Commit changes including the vendor tarball
    git add "${SPEC_FILE}" "vendor-${LATEST_VERSION}.tar.gz"
    git commit -m "cliphist: update to ${LATEST_VERSION}" || true
    git tag -f "cliphist-v${LATEST_VERSION}"
else
    echo "Warning: vendor tarball not found"
    # Commit spec file only
    git add "${SPEC_FILE}"
    git commit -m "cliphist: update to ${LATEST_VERSION}" || true
    git tag -f "cliphist-v${LATEST_VERSION}"
fi
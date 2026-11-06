#!/usr/bin/env bash
# Updates packages/solidcraft/package.nix to the latest stable GitHub release.
# Uses the sha256 digest GitHub already publishes — no download needed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_FILE="${SCRIPT_DIR}/package.nix"
REPO="bherbruck/solidcraft"

LATEST_TAG=$(gh release list --repo "$REPO" --limit 1 --exclude-pre-releases --json tagName --jq '.[0].tagName')
VERSION="${LATEST_TAG#v}"

CURRENT_VERSION=$(grep 'version = ' "$PKG_FILE" | head -1 | sed 's/.*version = "\(.*\)".*/\1/')
if [ "$VERSION" = "$CURRENT_VERSION" ]; then
  echo "Already at latest: v${VERSION}"
  exit 0
fi

echo "Updating $REPO: v${CURRENT_VERSION} → v${VERSION}"

ASSET_NAME="solidcraft-${VERSION}-linux-x86_64.AppImage"
HEX_HASH=$(gh release view "$LATEST_TAG" --repo "$REPO" --json assets \
  --jq ".assets[] | select(.name == \"${ASSET_NAME}\") | .digest" | sed 's/sha256://')

if [ -z "$HEX_HASH" ]; then
  echo "Error: could not find asset ${ASSET_NAME} in release ${LATEST_TAG}" >&2
  exit 1
fi

SRI_HASH=$(python3 -c "import base64, binascii; print('sha256-' + base64.b64encode(binascii.unhexlify('${HEX_HASH}')).decode())")

sed -i \
  -e "s/version = \"[^\"]*\"/version = \"${VERSION}\"/" \
  -e "s|hash = \"sha256-[^\"]*\"|hash = \"${SRI_HASH}\"|" \
  "$PKG_FILE"

echo "Done — ${PKG_FILE} updated to v${VERSION}"
echo "Run: sudo nixos-rebuild switch --flake ~/nixos-dotfiles"

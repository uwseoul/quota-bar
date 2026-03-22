#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DIST_DIR="$PROJECT_ROOT/dist"
UPDATES_DIR="$PROJECT_ROOT/updates"

BUILD_SCRIPT="$SCRIPT_DIR/build-universal.sh"
PREREQ_SCRIPT="$SCRIPT_DIR/check-release-prereqs.sh"

REPO_SLUG="${REPO_SLUG:-uwseoul/glm-bar}"

if [[ -z "${RELEASE_VERSION:-}" ]]; then
    echo "RELEASE_VERSION is required (example: 1.0.1)." >&2
    exit 1
fi

if [[ -z "${RELEASE_BUILD_NUMBER:-}" ]]; then
    echo "RELEASE_BUILD_NUMBER is required (example: 101)." >&2
    exit 1
fi

RELEASE_TAG="${RELEASE_TAG:-v$RELEASE_VERSION}"

require_file() {
    local file_path="$1"
    if [[ ! -f "$file_path" ]]; then
        echo "Required file missing: $file_path" >&2
        exit 1
    fi
}

require_file "$BUILD_SCRIPT"
require_file "$PREREQ_SCRIPT"

"$PREREQ_SCRIPT"

echo "[release] Building release artifacts..."
RELEASE_BUILD=1 RELEASE_VERSION="$RELEASE_VERSION" RELEASE_BUILD_NUMBER="$RELEASE_BUILD_NUMBER" "$BUILD_SCRIPT"

APP_BUNDLE="$DIST_DIR/GLMBar.app"
APP_ZIP="$DIST_DIR/GLMBar.zip"
CLI_TAR="$DIST_DIR/glm-bar-macos.tar.gz"

require_file "$APP_ZIP"
require_file "$CLI_TAR"

if [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" && -n "${APPLE_TEAM_ID:-}" ]]; then
    echo "[release] Notarizing app archive..."
    xcrun notarytool submit "$APP_ZIP" \
        --apple-id "$APPLE_ID" \
        --password "$APPLE_APP_SPECIFIC_PASSWORD" \
        --team-id "$APPLE_TEAM_ID" \
        --wait

    echo "[release] Stapling notarization ticket..."
    xcrun stapler staple "$APP_BUNDLE"

    echo "[release] Repackaging stapled app bundle..."
    rm -f "$APP_ZIP"
    pushd "$DIST_DIR" >/dev/null
    zip -r -q "GLMBar.zip" "GLMBar.app"
    popd >/dev/null

    echo "[release] Validating Gatekeeper acceptance..."
    spctl -a -vvv -t execute "$APP_BUNDLE"
else
    echo "[release] Skipping notarization (Apple credentials not provided)."
    echo "[release] Users will see 'unidentified developer' warning on first launch."
fi

echo "[release] Success"
echo "  - App bundle: $APP_BUNDLE"
echo "  - App archive: $APP_ZIP"
echo "  - CLI archive: $CLI_TAR"

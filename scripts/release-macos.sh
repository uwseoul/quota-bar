#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DIST_DIR="$PROJECT_ROOT/dist"
UPDATES_DIR="$PROJECT_ROOT/updates"

BUILD_SCRIPT="$SCRIPT_DIR/build-universal.sh"
PREREQ_SCRIPT="$SCRIPT_DIR/check-release-prereqs.sh"
APPCAST_BIN="$PROJECT_ROOT/vendor/bin/generate_appcast"
SIGN_UPDATE_BIN="$PROJECT_ROOT/vendor/bin/sign_update"

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
DOWNLOAD_URL_PREFIX="https://github.com/${REPO_SLUG}/releases/download/${RELEASE_TAG}"

require_file() {
    local file_path="$1"
    if [[ ! -f "$file_path" ]]; then
        echo "Required file missing: $file_path" >&2
        exit 1
    fi
}

require_file "$BUILD_SCRIPT"
require_file "$PREREQ_SCRIPT"
require_file "$APPCAST_BIN"
require_file "$SIGN_UPDATE_BIN"

if [[ -z "${SPARKLE_PRIVATE_KEY:-}" ]]; then
    echo "SPARKLE_PRIVATE_KEY is required for signing update archives and appcast." >&2
    exit 1
fi

if [[ "$SPARKLE_PRIVATE_KEY" == "RELEASE_SPARKLE_PRIVATE_KEY_PLACEHOLDER" ]]; then
    echo "SPARKLE_PRIVATE_KEY is a placeholder value. Use a real private key." >&2
    exit 1
fi

"$PREREQ_SCRIPT"

echo "[release] Building release artifacts..."
RELEASE_BUILD=1 RELEASE_VERSION="$RELEASE_VERSION" RELEASE_BUILD_NUMBER="$RELEASE_BUILD_NUMBER" "$BUILD_SCRIPT"

APP_BUNDLE="$DIST_DIR/GLMBar.app"
APP_ZIP="$DIST_DIR/GLMBar.zip"
CLI_TAR="$DIST_DIR/glm-bar-macos.tar.gz"
APP_INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"

require_file "$APP_ZIP"
require_file "$CLI_TAR"
require_file "$APP_INFO_PLIST"

embedded_public_key="$(/usr/libexec/PlistBuddy -c "Print :SUPublicEDKey" "$APP_INFO_PLIST" 2>/dev/null || true)"
if [[ -z "$embedded_public_key" || "$embedded_public_key" == "RELEASE_SPARKLE_PUBLIC_KEY_PLACEHOLDER" ]]; then
    echo "SUPublicEDKey is missing or still placeholder in built app bundle." >&2
    exit 1
fi

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

echo "[release] Preparing updates staging directory..."
rm -rf "$UPDATES_DIR"
mkdir -p "$UPDATES_DIR"
cp "$APP_ZIP" "$UPDATES_DIR/"

if [[ -n "${RELEASE_NOTES_FILE:-}" ]]; then
    if [[ ! -f "$RELEASE_NOTES_FILE" ]]; then
        echo "RELEASE_NOTES_FILE was provided but does not exist: $RELEASE_NOTES_FILE" >&2
        exit 1
    fi
    cp "$RELEASE_NOTES_FILE" "$UPDATES_DIR/GLMBar.md"
fi

echo "[release] Signing archive with Sparkle key..."
printf '%s' "$SPARKLE_PRIVATE_KEY" | "$SIGN_UPDATE_BIN" --ed-key-file - "$UPDATES_DIR/GLMBar.zip" > "$UPDATES_DIR/sign_update_output.txt"

echo "[release] Generating appcast.xml..."
printf '%s' "$SPARKLE_PRIVATE_KEY" | "$APPCAST_BIN" \
    --ed-key-file - \
    --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
    --link "https://github.com/${REPO_SLUG}" \
    "$UPDATES_DIR"

APPCAST_FILE="$UPDATES_DIR/appcast.xml"
require_file "$APPCAST_FILE"

if ! grep -q "$DOWNLOAD_URL_PREFIX/GLMBar.zip" "$APPCAST_FILE"; then
    echo "Generated appcast.xml does not include expected enclosure URL prefix." >&2
    exit 1
fi

echo "[release] Success"
echo "  - App bundle: $APP_BUNDLE"
echo "  - App archive: $APP_ZIP"
echo "  - CLI archive: $CLI_TAR"
echo "  - Appcast: $APPCAST_FILE"
echo "  - Appcast URL target: ${DOWNLOAD_URL_PREFIX}/GLMBar.zip"

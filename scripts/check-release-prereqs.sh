#!/usr/bin/env bash
set -euo pipefail

NOTARY_PROFILE_NAME="${NOTARY_PROFILE_NAME:-glmbar-notary}"

# Required for Sparkle signing
REQUIRED_VARS=(
    "SPARKLE_PRIVATE_KEY"
)

# Optional for Apple notarization (skip if not available)
OPTIONAL_NOTARY_VARS=(
    "APPLE_ID"
    "APPLE_APP_SPECIFIC_PASSWORD"
    "APPLE_TEAM_ID"
    "APPLE_DEVELOPER_ID_APPLICATION"
)

missing_vars=()

for var_name in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var_name:-}" ]]; then
        missing_vars+=("$var_name")
    fi
done

if (( ${#missing_vars[@]} > 0 )); then
    echo "[release-prereqs] Missing required environment variables:" >&2
    for var_name in "${missing_vars[@]}"; do
        echo "  - $var_name" >&2
    done
    echo "[release-prereqs] Export all required variables and retry." >&2
    exit 1
fi

# Check if notarization is available
notarization_available=true
for var_name in "${OPTIONAL_NOTARY_VARS[@]}"; do
    if [[ -z "${!var_name:-}" ]]; then
        notarization_available=false
        break
    fi
done

if [[ "$notarization_available" == "true" ]]; then
    echo "[release-prereqs] OK: Apple notarization credentials are present."
    echo "[release-prereqs] Notary keychain profile contract: $NOTARY_PROFILE_NAME"
else
    echo "[release-prereqs] NOTE: Apple notarization credentials not found. Skipping notarization."
    echo "[release-prereqs] Users will see 'unidentified developer' warning on first launch."
fi

echo "[release-prereqs] OK: all required release environment variables are present."

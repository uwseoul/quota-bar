#!/usr/bin/env bash
set -euo pipefail

OPTIONAL_NOTARY_VARS=(
    "APPLE_ID"
    "APPLE_APP_SPECIFIC_PASSWORD"
    "APPLE_TEAM_ID"
)

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
    if [[ -n "${APPLE_DEVELOPER_ID_APPLICATION:-}" ]]; then
        echo "[release-prereqs] OK: Developer ID application identity is available for signing."
    else
        echo "[release-prereqs] NOTE: APPLE_DEVELOPER_ID_APPLICATION is not set in the shell environment."
    fi
else
    echo "[release-prereqs] NOTE: Apple notarization credentials not found. Skipping notarization."
    echo "[release-prereqs] Users will see 'unidentified developer' warning on first launch."
fi

echo "[release-prereqs] OK: Ready to build release."

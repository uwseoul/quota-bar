# Releasing GLMBar

This runbook covers local and CI release steps for packaged GitHub Releases.

## Scope

- `GLMBar.app` exposes an in-app "Check for Updates..." action that checks the latest GitHub release.
- Both `GLMBar.app` and `glm-bar` are distributed through GitHub Releases.
- There is no Sparkle feed or appcast generation in the current release flow.

## Required Secrets

Release pipeline can use:

- `APPLE_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`
- `APPLE_TEAM_ID`
- `APPLE_DEVELOPER_ID_APPLICATION` (only if your signing flow needs it in the shell environment)

## Local Release

1. Validate prerequisites.

```bash
./scripts/check-release-prereqs.sh
```

2. Build release archives, then notarize and staple when Apple credentials are available.

```bash
RELEASE_VERSION=1.0.1 RELEASE_BUILD_NUMBER=101 RELEASE_TAG=v1.0.1 ./scripts/release-macos.sh
```

3. Verify outputs.

- `dist/GLMBar.app`
- `dist/GLMBar.zip`
- `dist/glm-bar-macos.tar.gz`

4. Confirm the GitHub Release contains the expected assets for the tag.

## CI Release (GitHub Actions)

- Workflow: `.github/workflows/release.yml`
- Trigger: push tag matching `v*`
- Outputs:
  - GitHub Release assets: `dist/GLMBar.zip`, `dist/glm-bar-macos.tar.gz`

Tag and push:

```bash
git tag v1.0.1
git push origin v1.0.1
```

## Version Rules

- `RELEASE_VERSION` should match the semantic tag without `v`.
- `RELEASE_TAG` should include `v` prefix.
- `RELEASE_BUILD_NUMBER` should be monotonic.

## Recovery Guide

### Missing certificate identity

- Symptom: prereq script fails identity check.
- Action: install the Developer ID certificate into login keychain and retry `./scripts/check-release-prereqs.sh`.

### Notarization rejected

- Symptom: `xcrun notarytool submit ... --wait` fails.
- Action: inspect notarization log, fix signature/runtime entitlement issue, rerun release script.

### Release assets missing

- Symptom: GitHub Release completes without `GLMBar.zip` or `glm-bar-macos.tar.gz`.
- Action: inspect `.github/workflows/release.yml` and local `dist/` outputs, then rerun the release after the build step succeeds.

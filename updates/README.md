# Updates Directory

This directory is reserved for release-related metadata or staged update assets, but the current release pipeline does not publish it.

Current behavior:

- `.github/workflows/release.yml` publishes release assets directly to GitHub Releases
- `scripts/release-macos.sh` builds `dist/GLMBar.zip` and `dist/glm-bar-macos.tar.gz`
- The app checks the latest GitHub release via the GitHub API and opens the Releases page when an update is available

There is currently no generated `appcast.xml` or GitHub Pages publishing step.

Do not commit private signing keys to this directory.

# Changelog

## v1.2.0+5

### New Providers
- Litterbox — temporary/expiring file hosting
- FileDitch — file hosting service
- Frisk — file hosting with 1-day expiry
- Favicon assets for all new providers

### New Features
- Custom share message — write your own message instead of broken `%url` template variables; message is persisted across sessions and always prepended above the URL
- Windows desktop build target
- GitHub Actions CI workflow for Windows builds
- Build script prints download URLs at the end

### Bug Fixes
- Image resize now actually applies before upload (was streaming original file from disk instead of resized bytes)
- Expiry info text no longer overflows its container on the provider info card
- Badge text now uses ellipsis overflow instead of clipping
- Version check widget no longer overflows on narrow screens
- GIT_HASH is now correctly passed as `--dart-define` in build script
- Build Android APK for arm64-v8a only (was producing fat APK with all architectures)

### Infrastructure
- Windows build workflow (GitHub Actions)
- Build script improvements: URL printing, changelog reminder

## v1.2.0+4

- use GitHub Releases for version check when CDN URL is not set
- nav layout preference (left/right/bottom), Linux AppImage build, build script improvements
- various documentation updates and screenshots

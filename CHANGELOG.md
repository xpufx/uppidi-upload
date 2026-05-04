# Changelog

## 1.0.0+1 (2026-05-04)

### Features
- Image preview with upload confirmation before every upload
- Theme: dark mode toggle, 6 color presets, custom logo
- Provider enable/disable switches + connectivity test page (Providers tab)
- Share URL button on upload result and history
- Drag-and-drop file upload on desktop (Linux, macOS, Windows)
- Animated upload progress with live speed (MB/s) and byte counter
- Desktop footer bar with app name + version
- Latest symlinks for easy download endpoints
- Upload retry: preview stays visible, retry button on failure
- Share with templated message: %url, %provider, %date, %filename variables
- Pre-build hardcoded string detection (grep-based lint)
- CHANGELOG.md + About card in Settings with View Changelog dialog
- Per-ABI Android APK builds (~20MB arm64)

### Fixes
- Cancel upload no longer leaves sticky error state
- Proxy URL now applied to upload connections (HTTP/HTTPS)
- App icon replaced with new logo (light/dark variants)
- Settings proxy field debounced at 500ms
- Animation memory leak fixed in progress section
- Dynamic types replaced with proper typing in upload screen
- Navigation button colors: selected (primary) / unselected (surface variant)
- All hardcoded UI strings localized (3 languages)
- Redundant logo removed from Providers page header
- Stale test count removed from settings

### Agents
- Archie (Architect) — DeepSeek V4 Pro
- Jeb (Junior executor) — MiniMax M2.5 (free)
- DJ (Docs) — BigPickle (free)
- Audrey (Audit) — Hy3 Preview (free)
- Theo (Tests) — Hy3 Preview (free)
- All agents repo-agnostic, model-agnostic nicknames

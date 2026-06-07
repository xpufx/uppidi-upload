# Session Summary — 2026-06-06

## Overview

Massive session covering providers, refactoring, website merge, MCP setup, emulator, and UI polish.

---

## 1. New Providers (4 + 1 investigasyon)

### Bzzhr.to (`lib/providers/bzzhr_provider.dart`)
- API: `PUT https://w.bzzhr.co/{filename}` raw binary → 201 JSON with `{code: 201, data: {id: "..."}}`
- Download URL: `https://bzzhr.co/{id}` (NOT `bzzhr.to` — `.to` domain has separate DB, files don't sync)
- Max size: ~100 MB, Expiry: ~4 days (from API response analysis)
- Favicon: `assets/favicons/bzzhr.png`

### Filebin.net (`lib/providers/filebin_provider.dart`)
- API: `POST https://filebin.net/{random_bin}/{filename}` raw binary + Content-Length header
- Response: `{bin: {id: "..."}, file: {filename: "..."}}` → URL: `https://filebin.net/{binId}/{fileName}`
- Max: 150 MB, 6 months expiry
- Favicon: `assets/favicons/filebin.png`

### Filester.me (`lib/providers/filester_provider.dart`)
- API: Multipart upload to `https://filester.me/upload`
- URL format: `https://filester.me/d/{slug}` (originally had 404 without `/d/`)
- Max: 100 GB, 30 days expiry
- Favicon: `assets/favicons/filester.png`

### Storage.to (`lib/providers/storage_to_provider.dart`)
- 3-step flow: init → PUT presigned URL → confirm
- Init: `POST /api/upload/init` with filename/content_type/size → returns r2_key + upload_url + owner_token
- PUT to S3/R2 presigned URL
- Confirm: `POST /api/upload/confirm` with r2_key + filename + size + content_type + optional owner_token
- Response: `{success: true, file: {url, raw_url, ...}}` → uses `raw_url` (preferred) or `url`
- **Fix**: MUST include `size` and `content_type` in confirm body — was missing, caused 302 redirect
- **Fix**: PUT response status code now checked — was ignoring failures
- Favicon: `assets/favicons/storage_to.png`

### bzzhr.to Proxy Page
- `https://bzzhr.to/proxy` lists domains: bzzhr.co, bzzhr.to, buzzheavier.com — all "Active"
- `w.bzzhr.co` is the upload worker for the bzzhr.co/buzzheavier.com instance
- No separate worker for bzzhr.to — it's just a branded frontend

---

## 2. Removal: Pixeldrain

**`lib/providers/pixeldrain_provider.dart`** removed from registry (file kept on disk as dead code).
- Anonymous API shut down — now requires `api_key` via HTTP Basic Auth
- Was behind `DEV_PROVIDERS`, then fully removed per user request
- Registry import deleted, `_baseTypes` entry removed

---

## 3. Major Refactor: BaseHttpProvider

**File:** `lib/core/interfaces/base_http_provider.dart`

### `_log` → `log` (public/protected)
- `late final Log _log` → `final Log log` (no `late` needed)
- All provider files updated: `late final Log _log = Log(...)` removed, `_log.xxx` → `log.xxx`
- 17 provider files affected

### Default getters moved to base class
```dart
supportsWeb => false
requiredConfigKeys => []
configLabels => const {}
proxyUrl => null
```
- Empty overrides removed from all providers
- Non-empty overrides kept (CustomUguu: `['server_url']`, Telegram: `['bot_token','chat_id']`, etc.)
- `supportsWeb => true` kept (HttpBin, GoFile)

### `prepareRequest(Object? config)` helper
- Strips internal keys (`_allow_insecure_conn`, `_proxy_url`, `_user_agent`)
- Creates HTTP client via `createHttpClient`
- Returns `PreparedRequest{dio, cleanedConfig, allowInsecure, proxyUrl, userAgent}`
- Used by: bzzhr, filebin, storage_to (raw binary providers)
- Also migrated: gofile, telegram, zulip (were doing manual config stripping)

### `parseJsonResponse(Response)` helper
- Handles both String (jsonDecode) and Map (Dio auto-parse) response bodies
- Returns `null` on failure — caller does `if (json == null) return unhandledError(response)`
- Used by: fileditch, frisk
- `dart:convert` import moved to base, removed from fileditch/frisk

### `unhandledError(response)` usage enforced
- Base class already had it but nobody called it
- Updated: fileditch, frisk, litterbox, tempsh — replaced inline `log.warn('Unhandled error (returning genericError)')` + `UploadResult(success: false, errorMessage: 'genericError')` with `return unhandledError(response);`

### `PreparedRequest` class
```dart
class PreparedRequest {
  final Dio dio;
  final Map<String, String> cleanedConfig;
  final bool allowInsecure;
  final String? proxyUrl;
  final String? userAgent;
}
```

### Config classes deleted
- `bzzhr_config.dart`, `filebin_config.dart`, `storage_to_config.dart` removed
- These providers have no provider-specific config keys — `prepareRequest` handles raw config
- GoFileConfig, TelegramConfig, ZulipConfig, MatterbridgeConfig kept (they have typed config keys)

### Related check updates
- `scripts/check_wide_config.dart` — now clean (was flagging the 3 providers before refactor)
- `scripts/check_untranslated_arb.dart` — `'userAgent'` added to `exemptedKeys`

### Tests
- `test/base_http_provider_test.dart` — 15 tests, all pass
- `test/providers_test.dart` — live tests for all new providers (RUN_LIVE_TESTS gate)
- Full suite: 199 passed, 8 skipped, 0 failed

---

## 4. Website Merge (`site/`)

**Repo:** `xpufx/uppidi-website` merged into `xpufx/uppidi-upload` as `site/`

### Steps
1. `git remote add website git@github.com:xpufx/uppidi-website.git`
2. `git subtree add --prefix=site website/main` (full history kept)
3. Branch: main, deployed via `.github/workflows/deploy-pages.yml` (GitHub Actions, not branch-based)
4. Old repo archived: `xpufx/uppidi-website` → archived with description "Moved to xpufx/uppidi-upload/site"

### Files
- `site/index.html`, `site/download.html`, `site/privacy.html`
- `site/assets/` (logo, favicons, provider-icons, screenshots)
- `site/style.css`, `site/CNAME`, `site/.nojekyll`

### AGENTS.md updated
- Line 6: "Part of the uppidi-upload repository under site/"
- All `~/code/uppidi` path references → `../`
- Added "## Git history" section about subtree merge

### Build script reminder
`scripts/build_and_serve.sh` — added website update reminder comment before version sync

### Website responsibility
`AGENTS.md` (root) now has "## Website responsibility" section:
- Add/remove provider → update site/index.html provider table
- Change feature → update site/index.html features list  
- Change platform support → update site/index.html + site/download.html
- Change build instructions → update site/download.html
- Site + app changes in same commit

---

## 5. Animation Fix: Hard Redraw on Upload Complete

**File:** `lib/screens/upload_screen.dart`

### Problem
```dart
ref.listen(uploadProvider, (prev, next) {
  if (prev.runtimeType != next.runtimeType) _restartStagger();
});
```
Every state transition (`InProgress` → `Completed`) reset ALL stagger animations, causing all cards to jump to opacity 0 and re-animate. Combined with `AnimatedSwitcher`'s own transition, there was a double-animation flash.

### Fix
```dart
ref.listen(uploadProvider, (prev, next) {
  if (prev.runtimeType != next.runtimeType) {
    if (prev is UploadInProgress && next is UploadCompleted) return;
    _restartStagger();
  }
});
```
- `InProgress → Completed`: skip stagger reset → only `AnimatedSwitcher` handles the content transition
- All other transitions (`Idle→FileSelected`, `FileSelected→InProgress`, `Completed→Idle/FileSelected`): normal stagger

---

## 6. Flutter Skill MCP Setup

### What was done
- `flutter pub add flutter_skill` (v0.9.36)
- `lib/main.dart`: added `FlutterSkillBinding.ensureInitialized()` behind `if (kDebugMode)`
- Committed to both Forgejo and GitHub

### MCP Config (`~/.config/opencode/opencode.jsonc`)
```json
"flutter-skill": {
  "type": "local",
  "command": ["/home/xpufx/.pub-cache/bin/flutter_skill", "server"],
  "enabled": true
}
```

### Key Insight
This session's agent couldn't see the flutter-skill MCP tools because the session context predated the opencode restart. New agents (started after restart) see the tools properly.

### Usage
- `flutter_skill` binary installed via `dart pub global activate flutter_skill` and `npm install -g flutter-skill`
- Native binary also downloaded to `~/.flutter-skill/bin/` but v0.9.34 had issues
- MCP mode: opends from `flutter_skill server`, exposes 253 tools
- App must run with `--debug` for FlutterSkillBinding to be active
- `Flutter Skill Binding Initialized 🚀` log confirms it's working

### Limitations
- Native dialogs (file picker, permissions) not visible to flutter-skill — need ADB for those
- Tab navigation and screenshots work fine via MCP

---

## 7. Emulator

- AVD: `nsz_test` (Android 14, API 34, 1080x2400)
- Location: `~/.android/avd/nsz_test.avd`
- System image: `/home/xpufx/android/system-images/android-34/google_apis/x86_64/`
- Works with SwiftShader software rendering (`-gpu swiftshader_indirect`)
- Boot time: ~35 seconds cold, ~5 seconds snapshot
- ADB path: `/home/xpufx/android/platform-tools/adb`
- Flutter sees it as: `sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x64`
- StorageTo upload flow now checks PUT response

---

## 8. Pictures
 All screenshots are in `.caddy-artifacts/screenshots/` — not useful yet; no files selected.

---

## 9. Build Info

### Current HEAD
`2694c69` — `fix: smooth upload state transition — skip stagger reset on InProgress→Completed`

### Latest Dev Build
```
.caddy-artifacts/
├── uppidi-upload-1.5.2-2694c69-android-arm64-v8a.apk
├── uppidi-upload-1.5.2-2694c69-android-armeabi-v7a.apk
├── uppidi-upload-1.5.2-2694c69-android-x86_64.apk
├── uppidi-upload-1.5.2-2694c69-linux.tar.gz
├── uppidi-upload-1.5.2-2694c69-linux.flatpak
└── uppidi-upload-1.5.2-2694c69-x86_64.AppImage
```

### Version
`1.5.2` — all builds on this version (pubspec.yaml, lib/core/version.dart)

---

## 10. Remaining Issues (Minor)

Per agent `8893abfd` code review:
- **GoFile parseResponse**: uses manual `log.warn(...)` + genericError instead of `unhandledError(response)`
- **Telegram upload**: uses inline `MultipartFile.fromStream` instead of base's `_buildStreamFile` (private)
- **Matterbridge**: creates manual Dio instance instead of using `prepareRequest()`

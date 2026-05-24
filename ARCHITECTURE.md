# Uppidi Upload — Architecture

## Overview

**uppidi** is a cross-platform Flutter application for uploading media (images, video, text, files) to multiple free and self-hosted hosting services. It uses a strict **engine-and-plugin** architecture where each hosting site is a swap-in "Provider" implementing a common interface.

## Tech Stack

| Category | Library | Purpose |
|---|---|---|
| Language | Dart 3.x | Cross-platform via Flutter |
| Framework | Flutter 3.16+ | UI framework (6 platforms) |
| State Mgmt | `flutter_riverpod` ^3.3.1 | DI + reactive state — ALL mutable state flows through Riverpod providers, never read directly from storage |
| Local DB | `hive` + `hive_flutter` | Settings + upload history |
| Networking | `dio` ^5.9.2 | HTTP client, streaming, cancel tokens |
| i18n | `flutter_gen` + ARB files | Compile-time safe localizations |
| Image processing | `image` ^4.0.0 | Resize, crop, thumbnail |
| File picking | `file_picker` ^12.0.0 | Cross-platform file selection |
| Sharing | `share_plus` ^13.0.0 | OS share sheet |
| URL handling | `url_launcher` ^6.3.2 | Open links externally |
| Linting | `flutter_lints` ^6.0.0 | Default Flutter lints |

## Directory Structure

```
lib/
├── main.dart                          # App entry, Hive init, screen registration
├── core/
│   ├── interfaces/
│   │   ├── uploader.dart              # BaseUploader abstract class (plugin contract)
│   │   └── base_http_provider.dart    # BaseHttpProvider (common HTTP upload logic)
│   ├── models/
│   │   ├── provider_instance.dart       # ProviderInstance wrapper (multi-instance support)
│   │   ├── provider_metadata.dart       # Provider capabilities (file size, MIME, etc.)
│   │   ├── upload_record.dart           # Hive-serialized upload history
│   │   ├── upload_request.dart          # FileUploadRequest (stream-based)
│   │   └── upload_result.dart           # UploadResult (success/failure)
│   ├── platform/
│   │   ├── file_source.dart             # Conditional export stub/io
│   │   ├── file_source_stub.dart        # Web stub
│   │   ├── file_source_io.dart          # IO implementation
│   │   ├── insecure_adapter.dart        # Conditional export stub/io
│   │   ├── insecure_adapter_stub.dart   # Web stub
│   │   └── insecure_adapter_io.dart     # Self-signed cert adapter
│   ├── logging/
│   │   ├── log.dart                     # Logger wrapper around dart:developer
│   │   └── logging.dart                 # Barrel export
│   ├── config_provider.dart             # FutureProvider.family — loads all keys from secure storage
│   ├── provider_config_sheet.dart       # Config dialog + instance management
│   ├── registry.dart                   # ProviderRegistry (all providers list) + Riverpod providers
│   ├── settings_service.dart            # Hive-backed settings CRUD + settings providers
│   ├── history_service.dart             # Hive-backed upload history CRUD + providers
│   ├── theme_provider.dart              # Theme mode, seed color, logo path notifiers
│   ├── connectivity.dart                # Provider health check utility (uses configProvider)
│   ├── version.dart                     # Build-time injected git hash + version
│   ├── version_check_provider.dart      # CDN-based version check
│   ├── apk_installer.dart               # Android APK download + install
│   ├── app_logo.dart                    # Logo widget
│   ├── format.dart                      # Size formatting utility
│   ├── metadata_badges.dart             # Provider metadata badge widgets
│   ├── mime_types.dart                  # MIME type detection
│   ├── share_handler.dart               # Share intent handler (mobile)
│   ├── share_message_dialog.dart        # Share URL dialog
│   ├── share_template.dart              # Share message templates
│   └── android_save.dart                # Android SAF export workaround
├── providers/                         # Plugin implementations
│   ├── catbox_provider.dart           # Catbox.moe
│   ├── httpbin_provider.dart          # HttpBin.org (test)
│   ├── uguu_provider.dart             # Uguu.se
│   ├── tempsh_provider.dart           # Temp.sh
│   ├── freeimage_provider.dart        # Freeimage.host
│   ├── tmpfilelink_provider.dart      # TmpFile.link
│   ├── litterbox_provider.dart        # Litterbox.catbox.moe
│   ├── frisk_provider.dart            # Frisk.li
│   ├── fileditch_provider.dart        # FileDitch
│   ├── telegram_provider.dart         # Telegram (auth, multi-instance)
│   ├── zulip_provider.dart            # Zulip (auth, multi-instance)
│   ├── custom_uguu_provider.dart      # Uguu-compatible self-hosted (auth)
│   └── upload_provider.dart           # UploadNotifier (state machine + orchestration)
├── screens/
│   ├── shell_strategy.dart            # AppScreen enum + ScreenRegistry
│   ├── tab_nav_strategy.dart          # Bottom nav (mobile) / left rail (desktop)
│   ├── modal_nav_strategy.dart        # Alternative modal navigation
│   ├── upload_screen.dart             # Main upload UI
│   ├── history_screen.dart            # Upload history list
│   ├── history_modal.dart             # History as bottom sheet
│   ├── providers_modal.dart           # Provider list modal
│   ├── settings_screen.dart           # App settings
│   ├── settings_modal.dart            # Settings as modal
│   ├── test_screen.dart               # Provider health + enable/disable
│   └── modal_utils.dart               # Modal helper utilities
├── widgets/
│   ├── file_preview.dart              # Image preview with crop and quality selector
│   ├── progress_section.dart          # Animated upload progress bar
│   ├── result_banner.dart             # Upload result with share/copy/retry
│   ├── image_crop_overlay.dart        # Image crop UI overlay
│   └── provider_favicon.dart          # Provider favicon widget
├── l10n/
│   ├── intl_en.arb                    # English strings
│   ├── intl_eo.arb                    # Esperanto strings
│   ├── intl_it.arb                    # Italian strings
│   ├── intl_tr.arb                    # Turkish strings
│   ├── intl_tlh.arb                   # Klingon strings
│   ├── app_localizations.dart         # Generated localizations class
│   ├── app_localizations_en.dart      # Generated EN
│   ├── app_localizations_eo.dart      # Generated EO
│   ├── app_localizations_it.dart      # Generated IT
│   ├── app_localizations_tr.dart      # Generated TR
│   └── app_localizations_tlh.dart     # Generated TLH
test/
├── widget_test.dart                   # App smoke test
├── upload_screen_test.dart            # Upload screen widget tests
├── upload_provider_test.dart          # Upload provider state machine tests
├── test_screen_test.dart              # Test screen widget tests
├── providers_test.dart                # Live provider integration tests
├── core/
│   └── provider_config_test.dart      # Config persistence + registry tests
├── widgets/
│   └── settings_screen_test.dart
└── functional/
    ├── insecure_conn_functional_test.dart
    └── proxy_functional_test.dart
```

## Core Architecture: Engine & Plugin Model

> **Vision, not just description.** This document describes the target
> architecture. Code that deviates from these patterns (e.g. direct
> `FlutterSecureStorage` reads) is a known gap tracked for migration.
> See `docs/designdocs/riverpod-state.md` for the detailed rationale.

### The Contract (`lib/core/interfaces/uploader.dart`)

Every provider implements `BaseUploader` — the core abstract class:

```
BaseUploader (abstract)
├── providerId           — unique string id (e.g. "catbox")
├── providerName         — human-readable name
├── supportsWeb          — whether direct browser usage works
├── requiredConfigKeys   — config keys the provider needs
├── configLabels         — UI labels for config keys
├── proxyUrl             — optional URL for CORS bypass
├── metadata             — ProviderMetadata (capabilities)
├── createHttpClient()   — creates configured Dio instance
└── upload()             — streaming upload with progress + cancel
```

### BaseHttpProvider (`lib/core/interfaces/base_http_provider.dart`)

`BaseHttpProvider` extends `BaseUploader` providing:
- HTTP upload via `Dio` with `MultipartFile.fromStream()`
- Automatic config key stripping (`_allow_insecure_conn`, `_proxy_url`)
- Error mapping (cancel, timeout, connection, generic)
- Proxy configuration via `configureProxy()`
- Insecure connection support (self-signed certs)
- Debug logging toggle

Providers extend `BaseHttpProvider` and only override:
- `baseUrl`, `uploadEndpoint`, `fileFormFieldName`
- `additionalFormFields` (optional)
- `parseResponse()` — the only provider-specific logic

### Provider Registry (`lib/core/registry.dart`)

Two layers:

**Base types** — the static blueprints, registered in a single list:
```dart
final List<BaseUploader> _baseTypes = [
  HttpBinProvider(), FileDitchProvider(), FriskProvider(),
  UguuProvider(name: 'uguu.se', url: 'https://uguu.se'),
  TmpFileLinkProvider(), CatboxProvider(),
  FreeImageHostProvider(name: 'freeimage.host', url: 'https://freeimage.host'),
  TempShProvider(), LitterboxProvider(),
  TelegramProvider(), ZulipProvider(), CustomUguuProvider(),
];
```

**Instances** — configured copies of auth providers (Telegram, Zulip). Each
instance wraps a base type as `ProviderInstance(base, instanceId, name)`.
The `init()` method loads instances from `FlutterSecureStorage` at startup,
so auth providers only appear in the UI when configured.  `refresh()` reloads
instances without restarting the app.

The UI reads from `ProviderRegistry.all` which merges base types (non-auth)
with loaded instances (auth).  Adding a new auth provider = one line in
`_baseTypes` + one class implementing `BaseUploader`.

### Upload State Machine (`lib/providers/upload_provider.dart`)

```
UploadIdle → UploadFileSelected → UploadInProgress → UploadCompleted
                                                      ↓
                 UploadCompleted (error) → UploadFileSelected (retry)
                 UploadInProgress → UploadIdle (cancel)
```

**State classes (sealed):**
- `UploadIdle` — waiting for file pick
- `UploadFileSelected` — file picked, preview visible, quality selectable, message text editable
- `UploadInProgress` — active upload with progress, speed, CancelToken
- `UploadCompleted` — success (URL) or failure (error message)

**UploadNotifier** manages:
- File selection (via `FilePicker` or drag-drop or share intent)
- Quality compression (Original / Medium 50% / Low 25%)
- Image cropping (via `ImageCropOverlay`)
- Provider switching (preserves file preview)
- Upload execution with streaming, progress callbacks, speed calculation
- History persistence via `HistoryService`

### Navigation Shell

Two strategies, selected by `global.shell_type` setting:

| Strategy | Mobile | Desktop |
|---|---|---|
| `TabNavStrategy` (default) | `BottomNavigationBar` | `NavigationRail` (left) |
| `ModalNavStrategy` | Modal bottom sheets | Modals |

Screens are registered via `ScreenRegistry` (`lib/screens/shell_strategy.dart`):
- `AppScreen.upload` → `UploadScreen`
- `AppScreen.history` → `HistoryScreen`
- `AppScreen.providers` → `TestScreen`
- `AppScreen.settings` → `SettingsScreen`

### Data Flow

```
User taps Pick
  → FilePicker.platform.pickFiles()
  → createUploadRequest(file) → FileUploadRequest (stream-based)
  → UploadFileSelected state (preview displayed)

User taps Upload
  → provider.upload(request, onProgress, cancelToken, config)
  → config loaded via providerConfigProvider (Riverpod) — single readAll()
    replaces three separate manual secure storage loops
  → BaseHttpProvider.upload():
      → createHttpClient(config)
      → dio.post(endpoint, data: FormData.fromMap(fields))
      → parseResponse(response)
      → UploadResult (success/failure)
  → UploadCompleted state
  → HistoryService.add(UploadRecord)

Upload cancellation:
  → notifier.cancelUpload()
  → cancelToken.cancel('User cancelled')
  → DioException (cancel type)
  → UploadIdle state
```

### External Integrations

| Service | Type | Provider |
|---|---|---|
| HttpBin.org | Test echo server | HttpBinProvider |
| Catbox.moe | File hosting | CatboxProvider |
| Uguu.se | File hosting | UguuProvider |
| Temp.sh | Temporary file hosting | TempShProvider |
| TmpFile.link | Temporary file hosting | TmpFileLinkProvider |
| Freeimage.host | Image hosting | FreeImageHostProvider |
| Litterbox.catbox.moe | Temporary file hosting | LitterboxProvider |
| Frisk.li | File hosting | FriskProvider |
| FileDitch | File hosting | FileDitchProvider |
| Telegram | Chat with bot upload | TelegramProvider (auth, multi-instance) |
| Zulip | Team chat upload | ZulipProvider (auth, multi-instance) |
| Uguu-compatible | Self-hosted Uguu | CustomUguuProvider (auth, single-instance) |

### Configuration Management

**Riverpod-driven state principle:** Every piece of mutable data flows through a
Riverpod `Provider` or `NotifierProvider`.  Widgets never read storage directly
— they watch a provider.  Writing invalidates the provider and all watchers
rebuild automatically.  See `docs/designdocs/riverpod-state.md` for the full
rationale.

**Hive boxes:**
- `settings` (`Box<String>`) — all app settings as key-value pairs
- `uploadHistory` (`Box<UploadRecord>`) — persisted upload history

**Global settings keys** (`SettingsService`):
- `global.locale` — language code
- `global.theme_mode` — system/light/dark
- `global.seed_color` — Material You seed color
- `global.logo_path` — custom logo path
- `global.disabled_providers` — comma-separated disabled provider IDs
- `global.debug_logging` — toggle debug HTTP logging
- `global.shell_type` — tabs/modals navigation
- `global.allow_insecure_conn` — allow self-signed certs
- `global.proxy_url` — HTTP proxy for CORS bypass
- `global.default_share_provider` — default share template

**Per-provider config:** Keys are stored in `FlutterSecureStorage` with the
format `provider_config_{providerId}_{key}` and loaded via
`providerConfigProvider` — a `FutureProvider.family` that reads all keys
matching the prefix in a single `readAll()` call.  Consumers (upload,
connectivity) watch this provider instead of reading storage directly.
Writing invalidates the provider and all watchers update automatically.

### Version & Update System

- `lib/core/version.dart` — `appVersion`, `gitHash`, `cdnUrl` from build-time `--dart-define`
- `lib/core/version_check_provider.dart` — compares local git hash against CDN's `latest.txt`
- `lib/core/apk_installer.dart` — downloads new APK from CDN and launches install prompt

## Build & Deploy

- **Build:** Flutter standard (`flutter build apk`, `flutter build linux`, etc.)
- **Release script:** `scripts/build_and_serve.sh` — builds Android APK + Linux release, copies to `.caddy-artifacts/`, updates `latest.txt`
- **Versioning:** Update `version:` in `pubspec.yaml` AND `appVersion` in `lib/core/version.dart`
- **CDN:** Static files served via Caddy from `.caddy-artifacts/` directory
- **i18n:** Run `flutter gen-l10n` or `dart run build_runner build` to regenerate localizations from ARB files

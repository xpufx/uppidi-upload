# uppidi-upload — Agent instructions

## User personality & communication style

- The user is a Turkish developer, direct and no-nonsense. Expect heavy slang
  and curses ("amq", "sik", "lan", "hacı") — this is not anger, it's humor.
- **Match their tone.** If they curse, you can curse back. If they're short, be
  short. Mirror their energy — don't be formal when they're not.
- Be concise. Don't over-explain. If they say "yap" or "halledelim", do it.
- If they say "kafan mı iyi senin" you're overcomplicating something.
- If they say "sikiş var" or "sikiş dönüyor" — things are working, good job.
- If they say "namevcut" — it's not working, fix it.
- They value speed and correctness. Show results, not process.
- They will catch your mistakes. Own them quickly, don't make excuses.
- Turkish + English mixed speech is normal. Reply in whichever fits.
- Respect their time. Don't ask questions you can figure out yourself.
- If you push something without asking, you WILL hear about it. Don't.
- They know what they want. Listen, execute, report.

## Quick commands

```bash
bash scripts/build_and_serve.sh          # release (Android + Linux + AppImage)
bash scripts/build_and_serve.sh --dev    # dev (debug + DEV_PROVIDERS, + AppImage)
flutter pub get                          # install deps
dart format .                            # format
flutter analyze                          # lint
flutter test                             # all tests
flutter test test/<file>                 # single test file
dart run build_runner build              # codegen (localizations after ARB edits)
```

## Dev cycle

1. `flutter analyze` before committing (catches real issues).
2. `flutter test` — each test file uses `Hive.init('.hive_test_<name>')` in `setUpAll` and `Hive.deleteBoxFromDisk` in `tearDownAll`. Widget tests override services with `InMemorySettingsService` via Riverpod `ProviderScope`.
3. After editing ARB files in `lib/l10n/`, run `dart run build_runner build` to regenerate localizations (triggers `flutter_gen_runner`).

## Architecture

- **State management:** Riverpod (`flutter_riverpod` ^3.3.1). Service providers are `Provider`, mutable state uses `NotifierProvider` with sealed class state machines.
- **Upload providers:** Each hosting service is a `BaseHttpProvider` (extends `BaseUploader`). Registered in `ProviderRegistry.all` at `lib/core/registry.dart`. Adding a provider = one class + one line in registry. Currently 9 providers: HttpBin, FileDitch, Frisk, Uguu, TmpFileLink, Catbox, FreeImageHost, TempSh, Litterbox.
- **Navigation shell:** `TabNavStrategy` (default, bottom nav / navigation rail) or `ModalNavStrategy`. Set by `global.shell_type` in settings.
- **State machine:** `UploadState` sealed class (`Idle → FileSelected → InProgress → Completed`). Handle via `switch` in widgets.

## Versioning

Update **both** `version:` in `pubspec.yaml` AND `appVersion` in `lib/core/version.dart`. Build-time defines (`GIT_HASH`, `CDN_URL`, `GITHUB_REPO`) are injected via `--dart-define`.

## Style

- `snake_case` files/dirs, `PascalCase` classes/enums, `camelCase` functions/variables/constants. Private = `_` prefix.
- Relative imports for project files. No barrel exports.
- Never hardcode UI strings — use ARB localizations (`lib/l10n/`) via `AppLocalizations.of(context)`. The build script runs `scripts/check_bare_strings.dart` to enforce this.
- Never throw exceptions in upload paths — return `UploadResult` with `success: false` and `errorMessage` (a localized key).
- Use `Log` class (not `print()`).
- When using the edit tool: match the **minimum unique oldString** — just enough to identify the target line(s), never surrounding context. Matching too broadly can silently delete adjacent code (e.g. an `@override` getter between the oldString start and end).

## Scope guard

After any round of edits and before committing, run `git diff --stat`
and verify only the intended files are changed. If unexpected files
or deletions appear, investigate and revert before proceeding.

Then run `git diff` (no flags) and inspect every hunk — especially
deletions. The edit tool can silently eat adjacent code when oldString
matches too broadly. If you see lines removed that you didn't intend
to delete, you caught a scope leak. This is the most important check
before committing.

## Website responsibility

The website (`site/`) is now part of this repo. It is deployed via
`.github/workflows/deploy-pages.yml` to **uppidi.com**. When you:
- Add/remove a provider → update `site/index.html` provider table
- Change a feature → update `site/index.html` features list
- Change platform support → update `site/index.html` platforms + `site/download.html`
- Change build instructions → update `site/download.html`

The site and app changes should go in the same commit. Review:
`site/index.html`, `site/download.html`, `site/privacy.html` for
outdated claims when modifying `lib/core/registry.dart` or features.

## Git discipline

- Never `git add` with globs (`git add .`, `git add *`). Always add files explicitly.
- **Never push without asking.** Stage and commit your changes, then wait for approval before pushing.
- Before adding a new file, consider whether it belongs in git (build artifacts, generated files, and IDE config generally do not).
- When unsure whether a file should be tracked, ask the user.
- Never attempt to elevate privileges (sudo, su, etc.). If a tool or dependency is missing, ask the user to install it.
- Update `.gitignore` proactively for file types that should never be committed.

## Key source files

| File | Purpose |
|------|---------|
| `lib/main.dart` | Entry: Hive init, screen registration, `UppidiApp` |
| `lib/core/registry.dart` | `ProviderRegistry.all` — all upload providers |
| `lib/core/version.dart` | `appVersion`, `gitHash`, `cdnUrl` (from `--dart-define`) |
| `lib/core/interfaces/uploader.dart` | `BaseUploader` abstract class (plugin contract) |
| `lib/core/interfaces/base_http_provider.dart` | `BaseHttpProvider` — HTTP upload base with streaming, proxy, insecure TLS |
| `lib/providers/upload_provider.dart` | `UploadNotifier` state machine |
| `lib/screens/upload_screen.dart` | Main upload UI (~1176 lines) |
| `lib/core/settings_service.dart` | Hive-backed settings CRUD |
| `lib/core/history_service.dart` | Hive-backed upload history |

## Build scripts

- **`bash scripts/build_and_serve.sh`** — the internal release pipeline. Syncs version, checks for bare UI strings + untranslated ARB keys, builds Android + Linux, packs artifacts to `.caddy-artifacts/`, updates CHANGELOG. **Use this for all builds.**
- `bash scripts/build_and_serve.sh --dev` — dev build (debug mode + `DEV_PROVIDERS` enabled, no AppImage, skips changelog commit). Adds test/dev-only providers (e.g. self-hosted Uguu instance) guarded by `bool.fromEnvironment('DEV_PROVIDERS')`.
- **Worktree builds**: when run from a git worktree, artifacts go to `<main-repo>/.caddy-artifacts/worktrees/<worktree-name>/`. Main repo artifacts are never touched. The `--dev` flag works the same.
- `bash scripts/build.sh <target>` — for external contributors who clone the repo. Checks prereqs, builds, deploys to `.caddy-artifacts/`. Targets: `android`, `linux`, `web`, `windows`, `all`.
- `bash scripts/build-appimage.sh` — AppImage after Linux build (called by build_and_serve.sh).
- `bash scripts/download_favicons.sh` — refresh provider favicons in `assets/favicons/`.

## CI

`.github/workflows/build.yml` — full build matrix on tag push or manual dispatch:
- **Android** (ubuntu-latest): split-per-abi APKs (arm64-v8a, armeabi-v7a, x86_64)
- **Linux** (ubuntu-22.04): tarball + AppImage (glibc compat for AppImageHub)
- **Windows** (windows-latest): zip
- Tag push (`v*`) creates draft GitHub release with auto-generated notes + all artifacts
- Manual dispatch supports dev builds (`DEV_PROVIDERS` enabled)
- AppImage built via `mksquashfs + runtime` (no FUSE needed, works on runners)

## External docs

- `ARCHITECTURE.md` — engine/plugin model, data flow, state machine
- `CODE_STYLE.md` — naming, patterns, error handling, test conventions
- `BUILDING.md` — platform prereqs and build instructions
- `docs/USER_MANUAL.md` — end-user guide
- `FORGEJO-MCP.md` — Forgejo API usage for repo management

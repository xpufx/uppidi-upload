# Test Philosophy

## No bullshit

Don't test constructors, getters, sealed class exhaustiveness, or
compiler-enforced behavior. If the compiler catches it, don't write a
test for it. `state_test.dart` and `models_test.dart` were deleted for
this reason. Don't bring them back.

## Real endpoints preferred

Live provider tests run by default — they're opt-out, not opt-in. A
provider that's down will fail the test, and that's fine. We want to
know. Transient failures (503, network blip) are acceptable.

Set `SKIP_LIVE_TESTS=1` to skip live endpoint tests when you're
offline or don't care about provider availability.

## No dead code

Tests that are always skipped get deleted. If a provider permanently
goes down, remove its live test. If a test's assertions are meaningless
("verify the screen renders without errors"), delete the test.

## No duplicates

`test_screen_test.dart` was deleted because every scenario was already
covered in `provider_ui_test.dart`. Check what's already tested before
writing new widget tests.

## What we test

| Category | Location | What |
|----------|----------|------|
| Functional | `test/functional/` | Real TLS server, real proxy server |
| State machine | `test/upload_provider_test.dart` | UploadNotifier transitions, errors, cancellation |
| Provider parsing | `test/provider_unit_test.dart` | Each provider's custom `parseResponse` |
| Live endpoints | `test/providers_test.dart` | Real upload to each provider (opt-out via `SKIP_LIVE_TESTS`) |
| Services | `test/core/` | SettingsService, HistoryService (Hive-backed CRUD) |
| Widgets | `test/widgets/`, `test/*_test.dart` | State-dependent rendering per screen |

## What we don't test

- Plain data class constructors
- Compiler-verified behavior (sealed classes, `copyWith`)
- Logging infrastructure
- Platform channel stubs
- Widgets already covered by parent widget tests

## Adding a provider

1. Add the class in `lib/providers/`
2. Register it in `lib/core/registry.dart`
3. Add `parseResponse` unit test in `test/provider_unit_test.dart`
4. Add live upload test in `test/providers_test.dart`
5. Update `site/index.html` provider table

## Running tests

```bash
flutter test                          # all tests (except live if SKIP_LIVE_TESTS is set)
flutter test test/providers_test.dart # live endpoint tests only
SKIP_LIVE_TESTS=1 flutter test        # skip live tests (offline-friendly)
```

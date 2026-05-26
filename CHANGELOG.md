# Changelog

## 1.4.0 — "What's worth doing, is worth overdoing!"

### New Providers
- **Telegram** — full Bot API uploader with multi-instance support. Send files as documents or images with captions, `send_as_photo` toggle, message template support.
- **Zulip** — Zulip server uploader. Channel/DM SegmentedButton toggle, API-fetched channel and user dropdowns, message posting to streams or direct messages.
- **CustomUguu** — self-hosted Uguu-compatible provider for your own server.
- **Matterbridge** — relay files to IRC, Discord, Telegram, Slack, Matrix, and other protocols via the Matterbridge API. Requires an existing Matterbridge server. Configure URL + token, fetch available gateways, pair with an upload provider (Catbox, Uguu, etc.) for text-only protocols.

### New Features
- Desktop drag-and-drop — real OS file drops from file manager with hover overlay (Linux, macOS, Windows).
- Clipboard paste — paste images from clipboard via the paste button.
- Global message template — configure in Settings, pre-filled on every upload, editable per-upload. Variables: {url} {filename} {filesize}.
- History "Share via Matterbridge" — post any past upload's URL to a Matterbridge gateway.

### Architecture
- Riverpod config provider — single source of truth for all config. Enforced by `check_raw_storage` in CI.
- Typed config classes — MatterbridgeConfig, TelegramConfig, ZulipConfig with named fields instead of raw Map<String, String>.
- Export/Import through Riverpod — reads per-provider, invalidates after write.
- Static analyzers — three checks run in every build: bare strings, raw storage access, wide config types.
- httpbin.org integration test — full upload pipeline against a real HTTP endpoint.
- 180 tests, 0 analyzer issues, all checkers green.

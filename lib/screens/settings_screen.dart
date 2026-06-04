import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:open_filex/open_filex.dart';

import '../core/apk_installer.dart' show downloadFile;
import '../core/app_logo.dart';
import '../core/export_import.dart';
import '../core/logging/log.dart';
import '../core/registry.dart';
import '../core/settings_service.dart';
import '../core/theme_provider.dart';
import '../core/version.dart';
import '../core/version_check_provider.dart';
import '../l10n/app_localizations.dart';

final _log = Log('Settings');

final insecureConnProvider = FutureProvider<bool>((ref) async {
  final svc = ref.read(settingsServiceProvider);
  return svc.isInsecureConnAllowed();
});

final proxyUrlProvider = FutureProvider<String?>((ref) async {
  final svc = ref.read(settingsServiceProvider);
  return svc.getProxyUrl();
});

final _defaultShareProviderProvider = FutureProvider<String?>((ref) async {
  final svc = ref.read(settingsServiceProvider);
  return await svc.get(SettingsService.defaultShareProviderKey);
});
final debugLoggingProvider = FutureProvider<bool>((ref) async {
  final svc = ref.read(settingsServiceProvider);
  return svc.isDebugLoggingEnabled();
});
final shellTypeProvider = FutureProvider<String>((ref) async {
  final svc = ref.read(settingsServiceProvider);
  return await svc.getShellType();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.settings,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _GlobalToggles(),
          const SizedBox(height: 16),
          const _ExportImportCard(),
          const _MessageTemplateCard(),
          const _BottomCards(),
        ],
      ),
    );
  }
}

void _showSystemInfo(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context);
  final buffer = StringBuffer();
  buffer.writeln('=== BUILD ===');
  buffer.writeln('App: Uppidi Upload v$appVersion');
  buffer.writeln('Git Hash: $gitHash');
  buffer.writeln('');
  buffer.writeln('=== PLATFORM ===');
  buffer.writeln('OS: ${Platform.operatingSystem}');
  buffer.writeln('Version: ${Platform.operatingSystemVersion}');
  buffer.writeln('Locale: ${Platform.localeName}');
  buffer.writeln('');
  buffer.writeln('=== PROVIDERS ===');
  buffer.writeln('Total: ${ProviderRegistry.all.length}');
  final disabled = ref.read(disabledProviderIdsProvider).asData?.value ?? {};
  for (final p in ProviderRegistry.all) {
    final enabled = !disabled.contains(p.providerId);
    buffer
        .writeln('${enabled ? "✓" : "✗"} ${p.providerName} (${p.providerId})');
  }
  buffer.writeln('');
  buffer.writeln('=== THEME ===');
  final theme = ref.read(themeModeProvider);
  final seed = ref.read(seedColorProvider);
  buffer.writeln('Mode: ${theme.name}');
  buffer
      .writeln('Seed: 0x${seed.toARGB32().toRadixString(16).padLeft(8, '0')}');
  final text = buffer.toString();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.bug_report, size: 18),
          const SizedBox(width: 8),
          Text(l10n.systemInfo),
        ],
      ),
      content: SingleChildScrollView(
        child: SelectableText(text,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => SharePlus.instance.share(ShareParams(text: text)),
          icon: const Icon(Icons.share, size: 16),
          label: Text(l10n.share),
        ),
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.copiedToClipboard)),
            );
          },
          child: Text(l10n.copyAll),
        ),
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.ok)),
      ],
    ),
  );
}

class _VersionCheckWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(versionCheckProvider);

    // Watch the age ticker so this widget rebuilds every second to update
    // the "Xs ago" text — avoids the old `state = state` no-op hack.
    ref.watch(versionCheckAgeTicker);

    // Age text only for upToDate (checkmark state)
    String? ageText;
    if (state is VersionCheckUpToDate) {
      final seconds = DateTime.now().difference(state.lastChecked).inSeconds;
      ageText = seconds < 60
          ? l10n.secondsAgo(seconds)
          : l10n.minutesAgo(seconds ~/ 60);
    }

    return GestureDetector(
      onTap: state is VersionCheckChecking
          ? null
          : () => ref.read(versionCheckProvider.notifier).check(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          switch (state) {
            VersionCheckIdle() =>
              const Icon(Icons.refresh, size: 14, color: Colors.grey),
            VersionCheckChecking() => const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            VersionCheckUpToDate() =>
              const Icon(Icons.check_circle, size: 14, color: Colors.green),
            VersionCheckUpdateAvailable(
              :final downloadUrl,
              :final latestHash
            ) =>
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final url = downloadUrl.isNotEmpty
                          ? downloadUrl
                          : (Platform.isAndroid
                              ? '$cdnUrl/uppidi-upload-latest-android-arm64-v8a.apk'
                              : '$cdnUrl/uppidi-upload-latest-linux.tar.gz');
                      if (url.isEmpty) return;
                      final isMobile = Platform.isAndroid;
                      final label = isMobile ? 'Android APK' : 'Linux';

                      var received = 0, total = 0, speed = 0;
                      void Function(void Function())? update;
                      String? dlPath;
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => StatefulBuilder(
                          builder: (ctx, setState) {
                            update = setState;
                            final totalStr = total > 0
                                ? '${(total / 1048576).toStringAsFixed(1)} MB'
                                : '?';
                            final speedStr = speed > 0
                                ? '${(speed / 1048576).toStringAsFixed(1)} MB/s'
                                : '';
                            final pct = total > 0 ? received / total : null;
                            final complete = dlPath != null;
                            return AlertDialog(
                              title: Text(complete
                                  ? l10n.downloadComplete
                                  : l10n.downloadingFile(label)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: complete
                                    ? [
                                        const Icon(Icons.check_circle,
                                            size: 48, color: Colors.green),
                                        const SizedBox(height: 8),
                                        Text(l10n.apkDownloaded),
                                        const SizedBox(height: 4),
                                        SelectableText(dlPath,
                                            style:
                                                const TextStyle(fontSize: 11)),
                                      ]
                                    : [
                                        if (pct != null)
                                          LinearProgressIndicator(value: pct)
                                        else
                                          const LinearProgressIndicator(),
                                        const SizedBox(height: 8),
                                        Text(
                                            '${(received / 1048576).toStringAsFixed(1)} / $totalStr $speedStr',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      ],
                              ),
                              actions: complete
                                  ? [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text(l10n.done),
                                      ),
                                      FilledButton.icon(
                                        onPressed: () async {
                                          await OpenFilex.open(
                                            dlPath!,
                                            type:
                                                'application/vnd.android.package-archive',
                                          );
                                          if (ctx.mounted) Navigator.pop(ctx);
                                        },
                                        icon: const Icon(Icons.download_done,
                                            size: 18),
                                        label: Text(l10n.installNow),
                                      ),
                                    ]
                                  : null,
                            );
                          },
                        ),
                      );
                      try {
                        String? downloadedPath;
                        if (isMobile) {
                          downloadedPath =
                              await downloadFile(url, onProgress: (r, t, s) {
                            received = r;
                            total = t;
                            speed = s;
                            update?.call(() {});
                          });
                        } else {
                          downloadedPath =
                              await downloadFile(url, onProgress: (r, t, s) {
                            received = r;
                            total = t;
                            speed = s;
                            update?.call(() {});
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text(l10n.downloadedTo(downloadedPath))),
                            );
                          }
                        }
                        if (context.mounted) {
                          dlPath = downloadedPath;
                          update?.call(() {});
                        }
                      } catch (e) {
                        _log.error('Version check download failed: $e',
                            error: e);
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.download,
                          size: 24, color: Colors.orange.shade600),
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        latestHash,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
          },
          if (ageText != null)
            Text(ageText,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _GlobalToggles extends ConsumerStatefulWidget {
  const _GlobalToggles();

  @override
  ConsumerState<_GlobalToggles> createState() => _GlobalTogglesState();
}

class _GlobalTogglesState extends ConsumerState<_GlobalToggles> {
  late TextEditingController _proxyController;
  Timer? _proxyDebounce;

  @override
  void initState() {
    super.initState();
    _proxyController = TextEditingController();
    Future.microtask(_load);
    Future.microtask(() => ref.read(versionCheckProvider.notifier).check());
  }

  @override
  void dispose() {
    _proxyDebounce?.cancel();
    _proxyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final proxy = await ref.read(proxyUrlProvider.future);
    _proxyController.text = proxy ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final svc = ref.read(settingsServiceProvider);
    final insecureAsync = ref.watch(insecureConnProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.enableInsecure),
                  content: Text(l10n.selfSignedCertWarning),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n.ok))
                  ],
                ),
              ),
              child: Icon(Icons.info_outline,
                  size: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.5)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.enableInsecure)),
            Switch(
              value: insecureAsync.asData?.value ?? false,
              onChanged: (v) {
                svc.set(SettingsService.insecureConnKey, v.toString());
                ref.invalidate(insecureConnProvider);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Theme mode
        Text(l10n.themeMode, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Center(
          child: SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l10n.themeSystem),
                  icon: const Icon(Icons.brightness_auto)),
              ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l10n.themeLight),
                  icon: const Icon(Icons.light_mode)),
              ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l10n.themeDark),
                  icon: const Icon(Icons.dark_mode)),
            ],
            selected: {ref.watch(themeModeProvider)},
            onSelectionChanged: (sel) =>
                ref.read(themeModeProvider.notifier).setMode(sel.first),
          ),
        ),
        const SizedBox(height: 16),
        // Seed color
        Text(l10n.themeSeedColor,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: const [
            Colors.deepPurple,
            Colors.blue,
            Colors.teal,
            Colors.orange,
            Colors.pink,
            Colors.indigo,
            Colors.red,
            Colors.green,
            Colors.amber,
            Colors.cyan,
            Colors.brown,
            Colors.deepOrange,
          ].map((color) {
            final selected = ref.watch(seedColorProvider);
            final isSelected = selected.toARGB32() == color.toARGB32();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () =>
                    ref.read(seedColorProvider.notifier).setColor(color),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 6)
                          ]
                        : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(l10n.language),
            const Spacer(),
            DropdownButton<String>(
              value: ref.watch(localeCodeProvider).asData?.value ?? 'en',
              onChanged: (v) {
                if (v != null) {
                  svc.set(SettingsService.localeKey, v);
                  ref.invalidate(localeCodeProvider);
                }
              },
              items: [
                const DropdownMenuItem(
                    value: 'en', child: Text('\u{1F1EC}\u{1F1E7} English')),
                const DropdownMenuItem(value: 'eo', child: Text('Esperanto')),
                const DropdownMenuItem(
                    value: 'it', child: Text('\u{1F1EE}\u{1F1F9} Italiano')),
                const DropdownMenuItem(
                    value: 'tlh', child: Text('Klingon (tlhIngan)')),
                const DropdownMenuItem(
                    value: 'tr', child: Text('\u{1F1F9}\u{1F1F7} Türkçe')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: ref.watch(_defaultShareProviderProvider).asData?.value,
          decoration: InputDecoration(
            labelText: l10n.defaultForSharing,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.lastUsed)),
            ...ProviderRegistry.all.map((p) => DropdownMenuItem(
                  value: p.providerId,
                  child: Text(p.providerName),
                )),
          ],
          onChanged: (v) {
            if (v == null) {
              svc.remove(SettingsService.defaultShareProviderKey);
            } else {
              svc.set(SettingsService.defaultShareProviderKey, v);
            }
            ref.invalidate(_defaultShareProviderProvider);
          },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _proxyController,
          decoration: InputDecoration(
            labelText: l10n.proxyUrl,
            hintText: l10n.proxyHint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) {
            _proxyDebounce?.cancel();
            _proxyDebounce = Timer(const Duration(milliseconds: 500), () {
              if (v.isEmpty) {
                svc.remove(SettingsService.proxyUrlKey);
              } else {
                svc.set(SettingsService.proxyUrlKey, v);
              }
              ref.invalidate(proxyUrlProvider);
            });
          },
        ),
        const SizedBox(height: 16),
        // Debug logging toggle
        Row(
          children: [
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.debugLogging),
                  content: Text(l10n.debugLoggingDescription),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n.ok))
                  ],
                ),
              ),
              child: Icon(Icons.info_outline,
                  size: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.5)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.debugLogging)),
            Switch(
              value: ref.watch(debugLoggingProvider).asData?.value ?? false,
              onChanged: (v) async {
                await svc.setDebugLoggingEnabled(v);
                Log.enableFileLogging(v);
                ref.invalidate(debugLoggingProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        v
                            ? '${l10n.debugLogging} ${l10n.enabled}'
                            : '${l10n.debugLogging} ${l10n.disabled}',
                      ),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.list_alt, size: 20),
              tooltip: l10n.viewDebugLog,
              onPressed: () => _showDebugLog(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Shell type selector (tabs vs modals)
        Row(
          children: [
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.shellLayoutTitle),
                  content: Text(l10n.shellLayoutDescription),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n.ok))
                  ],
                ),
              ),
              child: Icon(Icons.info_outline,
                  size: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.5)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'tabs', label: Text(l10n.tabs)),
                  ButtonSegment(value: 'modals', label: Text(l10n.modals)),
                ],
                selected: {
                  ref.watch(shellTypeProvider).asData?.value ?? 'tabs'
                },
                onSelectionChanged: (Set<String> selected) async {
                  final type = selected.first;
                  await svc.setShellType(type);
                  ref.invalidate(shellTypeProvider);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Navigation layout selector — desktop only
        if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) ...[
          Row(
            children: [
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.navLayout),
                    content: Text(l10n.navLayoutDescription),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(l10n.ok))
                    ],
                  ),
                ),
                child: Icon(Icons.info_outline,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.5)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'left',
                      label: Text(l10n.navigationLeft),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    ButtonSegment(
                      value: 'bottom',
                      label: Text(l10n.navigationBottom),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                    ButtonSegment(
                      value: 'right',
                      label: Text(l10n.navigationRight),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                  selected: {
                    ref.watch(navigationLayoutProvider).asData?.value ?? 'left'
                  },
                  onSelectionChanged: (Set<String> selected) async {
                    final layout = selected.first;
                    await svc.setNavigationLayout(layout);
                    ref.invalidate(navigationLayoutProvider);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  void _showDebugLog(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.list_alt, size: 20),
            const SizedBox(width: 8),
            Text(l10n.viewDebugLog),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<String>(
            future: Log.fullLog,
            builder: (ctx, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final text = snapshot.data ?? '';
              if (text.isEmpty) {
                return Center(
                  child: Text(
                    l10n.noLogEntries,
                    style: TextStyle(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                  ),
                );
              }
              return SingleChildScrollView(
                child: SelectableText(
                  text,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final text = await Log.fullLog;
              if (text.isEmpty) return;
              Clipboard.setData(ClipboardData(text: text));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                      content: Text(l10n.debugLogCopied(l10n.viewDebugLog))),
                );
              }
            },
            child: Text(l10n.copy),
          ),
          TextButton(
            onPressed: () async {
              final text = await Log.fullLog;
              if (text.isNotEmpty) {
                SharePlus.instance.share(ShareParams(text: text));
              }
            },
            child: Text(l10n.share),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}

/// Shows a download progress dialog and downloads [url], installing it
/// on Android if applicable.
Future<void> _downloadAndInstall(
    BuildContext context, String url, String label) async {
  final l10n = AppLocalizations.of(context);
  var received = 0, total = 0, speed = 0;
  String? downloadedPath;
  void Function(void Function())? update;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) {
        update = setState;
        final totalStr =
            total > 0 ? '${(total / 1048576).toStringAsFixed(1)} MB' : '?';
        final speedStr =
            speed > 0 ? '${(speed / 1048576).toStringAsFixed(1)} MB/s' : '';
        final pct = total > 0 ? received / total : null;
        final complete = downloadedPath != null;
        return AlertDialog(
          title: Text(
              complete ? l10n.downloadComplete : l10n.downloadingFile(label)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!complete) ...[
                if (pct != null)
                  LinearProgressIndicator(value: pct)
                else
                  const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  '${(received / 1048576).toStringAsFixed(1)} / $totalStr $speedStr',
                  style: const TextStyle(fontSize: 12),
                ),
              ] else ...[
                const Icon(Icons.check_circle, size: 48, color: Colors.green),
                const SizedBox(height: 8),
                Text(l10n.apkDownloaded),
                const SizedBox(height: 4),
                SelectableText(downloadedPath,
                    style: const TextStyle(fontSize: 11)),
              ],
            ],
          ),
          actions: complete
              ? [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.done),
                  ),
                  FilledButton.icon(
                    onPressed: () async {
                      await OpenFilex.open(
                        downloadedPath!,
                        type: 'application/vnd.android.package-archive',
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.download_done, size: 18),
                    label: Text(l10n.installNow),
                  ),
                ]
              : null,
        );
      },
    ),
  );

  try {
    final path = await downloadFile(url, onProgress: (r, t, s) {
      received = r;
      total = t;
      speed = s;
      update?.call(() {});
    });
    downloadedPath = path;
    update?.call(() {});
  } catch (e) {
    _log.error('Download failed: $e', error: e);
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.downloadFailed('$e'))),
      );
    }
  }
}

/// ── Bottom cards (about, export/import, always visible) ──────

class _BottomCards extends ConsumerStatefulWidget {
  const _BottomCards();

  @override
  ConsumerState<_BottomCards> createState() => _BottomCardsState();
}

class _BottomCardsState extends ConsumerState<_BottomCards> {
  String _changelogText = 'Changelog not available';

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('CHANGELOG.md').then((t) {
      if (mounted) setState(() => _changelogText = t);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        const Divider(height: 32),
        _aboutCard(l10n, theme),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _aboutCard(AppLocalizations l10n, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AppLogo(size: 80),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.appTitle,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('v$appVersion ($gitHash)',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: theme.textTheme.bodySmall),
                      _VersionCheckWidget(),
                      const SizedBox(height: 2),
                      Text(Platform.operatingSystem,
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (cdnUrl.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.android, size: 20),
                    tooltip: l10n.downloadAndroid,
                    onPressed: () => _downloadAndInstall(
                        context,
                        '$cdnUrl/uppidi-upload-latest-android-arm64-v8a.apk',
                        'APK'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.desktop_windows, size: 20),
                    tooltip: l10n.downloadLinux,
                    onPressed: () => _downloadAndInstall(context,
                        '$cdnUrl/uppidi-upload-latest-linux.tar.gz', 'Linux'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.list_alt, size: 20),
                    tooltip: l10n.browseAllBuilds,
                    onPressed: () => launchUrl(Uri.parse(cdnUrl),
                        mode: LaunchMode.externalApplication),
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.code, size: 20),
                    tooltip: l10n.viewReleases,
                    onPressed: () => launchUrl(
                        Uri.parse('https://github.com/$githubRepo/releases'),
                        mode: LaunchMode.externalApplication),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSystemInfo(context, ref),
                    icon: const Icon(Icons.bug_report, size: 12),
                    label:
                        Text(l10n.info, style: const TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.changelogTitle),
                        content: SingleChildScrollView(
                          child: Text(_changelogText),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(l10n.ok),
                          ),
                        ],
                      ),
                    ),
                    icon: const Icon(Icons.list_alt, size: 12),
                    label: Text(l10n.changelogTitle,
                        style: const TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.license),
                        content: SingleChildScrollView(
                          child: Text(l10n.gplNotice),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(l10n.ok),
                          ),
                        ],
                      ),
                    ),
                    icon: const Icon(Icons.description, size: 12),
                    label: Text(l10n.license,
                        style: const TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ── Message template card ─────────────────────────────────────

class _MessageTemplateCard extends ConsumerWidget {
  const _MessageTemplateCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final templateAsync = ref.watch(globalMessageTemplateProvider);
    final controller =
        TextEditingController(text: templateAsync.asData?.value ?? '');

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.shareMessage,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                l10n.shareMessageDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: l10n.messageTemplate,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  helperText:
                      l10n.messageVariables('{url} {filename} {filesize}'),
                ),
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () async {
                    final svc = ref.read(settingsServiceProvider);
                    final text = controller.text.trim();
                    if (text.isEmpty) {
                      await svc.remove(SettingsService.messageTemplateKey);
                    } else {
                      await svc.set(SettingsService.messageTemplateKey, text);
                    }
                    ref.invalidate(globalMessageTemplateProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.messageTemplateSaved)),
                      );
                    }
                  },
                  icon: const Icon(Icons.save, size: 16),
                  label: Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ── Export/Import card (scrollable with settings) ─────────────────

class _ExportImportCard extends ConsumerWidget {
  const _ExportImportCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.exportImportTitle,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              l10n.exportImportDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.exportConfigTitle),
                        content: Text(l10n.exportConfigWarning),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(l10n.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(l10n.exportAction),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    try {
                      final path = await exportConfig(ref: ref);
                      if (path != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.exportedTo(path))),
                        );
                      }
                    } catch (e) {
                      _log.error('Export failed: $e', error: e);
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l10n.exportFailed),
                            content: SelectableText("$e"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(l10n.ok),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.upload, size: 16),
                  label: Text(l10n.exportAction),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.importConfigTitle),
                        content: Text(l10n.importConfigWarning),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(l10n.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(l10n.importAction),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    try {
                      final msg = await importConfig(ref: ref);
                      await ProviderRegistry.refresh(ref);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(msg)),
                        );
                      }
                    } catch (e) {
                      _log.error('Import failed: $e', error: e);
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l10n.importFailed),
                            content: SelectableText("$e"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(l10n.ok),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: Text(l10n.importAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

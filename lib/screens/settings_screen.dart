import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/apk_installer.dart' show downloadAndInstallApk, downloadFile;
import '../core/app_logo.dart';
import '../core/registry.dart';
import '../core/settings_service.dart';
import '../core/theme_provider.dart';
import '../core/version.dart';
import '../core/version_check_provider.dart';
import '../l10n/app_localizations.dart';

final insecureConnProvider = FutureProvider<bool>((ref) async {
  final svc = ref.read(settingsServiceProvider);
  return svc.isInsecureConnAllowed();
});

final proxyUrlProvider = FutureProvider<String?>((ref) async {
  final svc = ref.read(settingsServiceProvider);
  return svc.getProxyUrl();
});

final localeProvider = FutureProvider<String>((ref) async {
  final svc = ref.read(settingsServiceProvider);
  return (await svc.get(SettingsService.localeKey)) ?? 'en';
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.settings,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _GlobalToggles(),
      ],
    );
  }
}

void _showSystemInfo(BuildContext context, WidgetRef ref) {
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
  buffer.writeln(
      'Custom Logo: ${ref.read(logoPathProvider) != null ? "yes" : "no"}');

  final text = buffer.toString();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.bug_report, size: 18),
          SizedBox(width: 8),
          Text('System Info'),
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
          label: const Text('Share'),
        ),
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied to clipboard')),
            );
          },
          child: const Text('Copy All'),
        ),
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
      ],
    ),
  );
}

class _VersionCheckWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(versionCheckProvider);
    final notifier = ref.read(versionCheckProvider.notifier);
    final lastChecked = notifier.lastChecked;

    // Age text only for upToDate (checkmark state)
    String? ageText;
    if (lastChecked != null && state == VersionCheckState.upToDate) {
      final seconds = DateTime.now().difference(lastChecked).inSeconds;
      ageText = seconds < 60 ? '${seconds}s ago' : '${seconds ~/ 60}m ago';
    }

    return SizedBox(
      width: 120,
      height: 32,
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: state == VersionCheckState.checking
              ? null
              : () => ref.read(versionCheckProvider.notifier).check(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              switch (state) {
                VersionCheckState.idle =>
                  const Icon(Icons.refresh, size: 14, color: Colors.grey),
                VersionCheckState.checking => const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                VersionCheckState.upToDate =>
                  const Icon(Icons.check_circle, size: 14, color: Colors.green),
                VersionCheckState.updateAvailable => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cdnUrl.isNotEmpty)
                        GestureDetector(
                          onTap: () async {
                            final isMobile = Platform.isAndroid;
                            final url = isMobile
                                ? '$cdnUrl/uppidi-upload-latest-android-arm64-v8a.apk'
                                : '$cdnUrl/uppidi-upload-latest-linux.tar.gz';
                            final label = isMobile ? 'APK' : 'Linux';

                            var received = 0, total = 0, speed = 0;
                            void Function(void Function())? update;
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
                                  final pct =
                                      total > 0 ? received / total : null;
                                  return AlertDialog(
                                    title: Text('Downloading $label'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
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
                                  );
                                },
                              ),
                            );
                            try {
                              if (isMobile) {
                                await downloadAndInstallApk(url,
                                    onProgress: (r, t, s) {
                                  received = r;
                                  total = t;
                                  speed = s;
                                  update?.call(() {});
                                });
                              } else {
                                final path = await downloadFile(url,
                                    onProgress: (r, t, s) {
                                  received = r;
                                  total = t;
                                  speed = s;
                                  update?.call(() {});
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Downloaded to: $path')),
                                  );
                                }
                              }
                              if (context.mounted)
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                            } catch (e) {
                              if (context.mounted)
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.download,
                                size: 24, color: Colors.orange.shade600),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          notifier.latestHash ?? '',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600),
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
        ),
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
  String _changelogText = 'Changelog not available';

  @override
  void initState() {
    super.initState();
    _proxyController = TextEditingController();
    Future.microtask(_load);
    Future.microtask(() => ref.read(versionCheckProvider.notifier).check());
    rootBundle.loadString('CHANGELOG.md').then((t) {
      if (mounted) setState(() => _changelogText = t);
    }).catchError((_) {});
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
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                DropdownMenuItem(value: 'it', child: Text('Italiano')),
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
                  title: const Text('Shell Layout'),
                  content: const Text(
                    'Choose how screens are organized: "Tabs" uses a tab bar for navigation. "Modals" shows the upload screen always and opens other screens as dialogs.',
                  ),
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
                segments: const [
                  ButtonSegment(value: 'tabs', label: Text('Tabs')),
                  ButtonSegment(value: 'modals', label: Text('Modals')),
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
        const Divider(height: 32),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AppLogo(size: 56),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Uppidi Upload v$appVersion',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                  '${l10n.providersCount(ProviderRegistry.all.length)} · $gitHash',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey)),
                              const SizedBox(width: 4),
                              if (cdnUrl.isNotEmpty) _VersionCheckWidget(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (cdnUrl.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.android, size: 20),
                        tooltip: 'Download Android APK',
                        onPressed: () async {
                          var received = 0;
                          var total = 0;
                          var speed = 0;
                          void Function(void Function())? update;

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
                                return AlertDialog(
                                  title: const Text('Downloading APK'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (pct != null)
                                        LinearProgressIndicator(value: pct)
                                      else
                                        const LinearProgressIndicator(),
                                      const SizedBox(height: 8),
                                      Text(
                                          '${(received / 1048576).toStringAsFixed(1)} / $totalStr $speedStr',
                                          style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                          try {
                            final path = await downloadFile(
                              '$cdnUrl/uppidi-upload-latest-android-arm64-v8a.apk',
                              onProgress: (r, t, s) {
                                received = r;
                                total = t;
                                speed = s;
                                update?.call(() {});
                              },
                            );
                            if (context.mounted) {
                              Navigator.of(context, rootNavigator: true).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Downloaded to: $path')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.of(context, rootNavigator: true).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Download failed: $e')),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.desktop_windows, size: 20),
                        tooltip: 'Download Linux',
                        onPressed: () async {
                          var received = 0, total = 0, speed = 0;
                          void Function(void Function())? update;
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
                                return AlertDialog(
                                  title: const Text('Downloading Linux'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (pct != null)
                                        LinearProgressIndicator(value: pct)
                                      else
                                        const LinearProgressIndicator(),
                                      const SizedBox(height: 8),
                                      Text(
                                          '${(received / 1048576).toStringAsFixed(1)} / $totalStr $speedStr',
                                          style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                          try {
                            final path = await downloadFile(
                                '$cdnUrl/uppidi-upload-latest-linux.tar.gz',
                                onProgress: (r, t, s) {
                              received = r;
                              total = t;
                              speed = s;
                              update?.call(() {});
                            });
                            if (context.mounted) {
                              Navigator.of(context, rootNavigator: true).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Downloaded to: $path')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted)
                              Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.list_alt, size: 20),
                        tooltip: 'Browse all builds',
                        onPressed: () => launchUrl(Uri.parse(cdnUrl),
                            mode: LaunchMode.externalApplication),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _showSystemInfo(context, ref),
                  icon: const Icon(Icons.bug_report, size: 16),
                  label: const Text('System Info'),
                ),
                OutlinedButton.icon(
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
                  icon: const Icon(Icons.list_alt, size: 16),
                  label: Text(l10n.viewChangelog),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

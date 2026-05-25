import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/insecure_upload_warning.dart';
import '../core/interfaces/uploader.dart';
import '../core/metadata_badges.dart';
import '../core/models/provider_instance.dart';
import '../core/models/provider_metadata.dart';
import '../core/config_provider.dart';
import '../core/provider_config_sheet.dart';
import '../core/settings_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/upload_provider.dart';
import '../widgets/file_preview.dart';
import '../widgets/progress_section.dart';
import '../widgets/provider_favicon.dart';
import '../widgets/result_banner.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadProvider);
    final notifier = ref.read(uploadProvider.notifier);
    final providers = uploadState.providers;
    final provider = uploadState.selectedProviderIndex < providers.length
        ? providers[uploadState.selectedProviderIndex]
        : null;
    final webUnsupported = kIsWeb && provider != null && !provider.supportsWeb;
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows);

    // ── Scrollable content (preview, provider info, etc.) ──────────
    final scrollBody = Padding(
      padding: const EdgeInsets.all(16),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProviderDropdown(
                selectedIndex: uploadState.selectedProviderIndex,
                providers: providers,
                isUploading: uploadState is UploadInProgress,
                onChanged: (i) {
                  if (i != null) {
                    notifier.setProvider(i);
                    _scrollController.animateTo(0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut);
                  }
                },
              ),
              if (provider != null) ...[
                const SizedBox(height: 8),
                _ProviderInfo(provider: provider),
              ],
              if (provider != null) ...[
                const SizedBox(height: 8),
                _ProviderConfigStatus(provider: provider),
              ],
              if (webUnsupported) const _WebWarning(),
              switch (uploadState) {
                UploadFileSelected(
                  fileName: final n,
                  fileSizeBytes: final s,
                  mimeType: final m,
                  fileBytes: final b
                ) =>
                  Dismissible(
                    key: const ValueKey('file-preview'),
                    direction: DismissDirection.horizontal,
                    onDismissed: (_) => notifier.clearSelection(),
                    child: FilePreview(
                        fileName: n,
                        fileSize: s,
                        mimeType: m,
                        fileBytes: b,
                        provider: provider,
                        notifier: notifier),
                  ),
                UploadInProgress(
                  fileName: final fn,
                  fileSizeBytes: final fs,
                  mimeType: final m,
                  fileBytes: final fb
                )
                    when fn != null =>
                  FilePreview(
                      fileName: fn,
                      fileSize: fs,
                      mimeType: m,
                      fileBytes: fb,
                      provider: provider,
                      notifier: notifier),
                UploadCompleted(
                  fileName: final fn,
                  fileSizeBytes: final fs,
                  mimeType: final m,
                  fileBytes: final fb
                )
                    when fn != null =>
                  FilePreview(
                      fileName: fn,
                      fileSize: fs,
                      mimeType: m,
                      fileBytes: fb,
                      provider: provider,
                      notifier: notifier),
                _ => const SizedBox.shrink(),
              },
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

    // ── Bottom action bar (always visible) ─────────────────────────
    final bottomBar = SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: switch (uploadState) {
          UploadIdle() => _PickButton(notifier: notifier),
          UploadFileSelected() => _FileSelectedButtons(notifier: notifier),
          UploadInProgress(
            progress: final p,
            speedLabel: final sp,
            sentBytes: final sb,
            totalBytes: final tb
          ) =>
            ProgressSection(
              progress: p,
              speedLabel: sp,
              sentBytes: sb,
              totalBytes: tb,
              onCancel: notifier.cancelUpload,
            ),
          UploadCompleted(
            errorMessage: final e,
            lastResult: final r,
            fileName: final fn,
            fileSizeBytes: final fs,
            mimeType: final m,
            fileBytes: final fb
          ) =>
            ResultBanner(
              url: r.url,
              errorMessage: e,
              fileName: fn,
              fileSizeBytes: fs,
              mimeType: m,
              fileBytes: fb,
              provider: provider,
              lastResult: r,
              onRetry: e != null
                  ? () async {
                      final proceed =
                          await checkInsecureWarning(context, provider!, ref);
                      if (proceed) notifier.uploadSelected();
                    }
                  : null,
              onCancel: () => notifier.clearSelection(),
            ),
        },
      ),
    );

    final screen = SafeArea(
      child: Column(
        children: [
          Expanded(child: scrollBody),
          bottomBar,
        ],
      ),
    );

    if (isDesktop) {
      return DragTarget<String>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) {
          final lines = details.data.split(RegExp(r'[\r\n]+'));
          for (final line in lines) {
            final uri = Uri.tryParse(line.trim());
            if (uri != null && uri.scheme == 'file' && uri.path.isNotEmpty) {
              final path = Uri.decodeFull(uri.path);
              notifier.uploadFromFile(path, null);
              break; // takes first file only
            }
          }
        },
        builder: (context, candidateData, rejectedData) {
          final l10n = AppLocalizations.of(context);
          final isHovering = candidateData.isNotEmpty;
          return Stack(
            children: [
              screen,
              if (isHovering)
                Positioned.fill(
                  child: Container(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.08),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_upload,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              l10n.dropFileToUpload,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }
    return screen;
  }
}

class _ProviderDropdown extends StatelessWidget {
  final int selectedIndex;
  final List<BaseUploader> providers;
  final bool isUploading;
  final ValueChanged<int?> onChanged;

  const _ProviderDropdown({
    required this.selectedIndex,
    required this.providers,
    required this.isUploading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedProvider =
        selectedIndex < providers.length ? providers[selectedIndex] : null;
    return Tooltip(
      message: selectedProvider != null
          ? (selectedProvider is ProviderInstance
              ? selectedProvider.displayName
              : selectedProvider.providerName)
          : '',
      child: DropdownButton<int>(
        value: selectedIndex,
        isExpanded: true,
        onChanged: isUploading ? null : onChanged,
        items: providers.asMap().entries.map((entry) {
          final p = entry.value;
          final online = !kIsWeb || p.supportsWeb;
          return DropdownMenuItem(
            value: entry.key,
            enabled: online,
            child: Row(
              children: [
                ProviderFavicon(
                  providerId: p.providerId,
                  size: 20,
                  iconColor: online
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).disabledColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                  p is ProviderInstance ? p.displayName : p.providerName,
                  overflow: TextOverflow.ellipsis,
                  style: online
                      ? null
                      : TextStyle(color: Theme.of(context).disabledColor),
                )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProviderInfo extends StatelessWidget {
  final BaseUploader? provider;
  const _ProviderInfo({required this.provider});

  @override
  Widget build(BuildContext context) {
    final p = provider;
    if (p == null) return const SizedBox.shrink();
    final meta = p.metadata;
    final l10n = AppLocalizations.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            metadataBadges(meta),
            if (meta.maxFileSizeBytes != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.file_present_outlined,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.maxFileSize(formatSize(meta.maxFileSizeBytes!)),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            if (meta.allowedMimeTypes != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.acceptedFiles(
                          resolveMimeLabel(l10n, meta.mimeTypeLabel)),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            if (meta.expiryInfo != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.expiryInfo(resolveExpiry(l10n, meta.expiryInfo!)),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            if (meta.supportsDirectLink) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.link, size: 14, color: Colors.green.shade600),
                  const SizedBox(width: 6),
                  Text(
                    l10n.supportsDirectLinks,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                        ),
                  ),
                ],
              ),
            ],
            if (meta.requiresAccount) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.account_circle_outlined,
                      size: 14, color: Colors.orange.shade600),
                  const SizedBox(width: 6),
                  Text(
                    l10n.requiresAccount,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PickButton extends ConsumerWidget {
  final UploadNotifier notifier;
  const _PickButton({required this.notifier});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ElevatedButton(
      onPressed: () => notifier.pickAndUpload(),
      child: Text(l10n.pickAndUpload),
    );
  }
}

class _UploadButton extends ConsumerWidget {
  final UploadNotifier notifier;
  const _UploadButton({required this.notifier});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(uploadProvider);
    final provider = state.providers.asMap()[state.selectedProviderIndex];
    var isUrlShareOnly = provider?.isUrlShareOnly ?? false;
    // Matterbridge needs a paired provider to upload files (IRC gateways)
    if (provider?.providerId.startsWith('matterbridge') == true) {
      final config = ref.watch(providerConfigProvider(provider!.providerId));
      final paired = config.asData?.value['paired_provider'] ?? '';
      isUrlShareOnly = paired.isEmpty;
    }

    return ElevatedButton.icon(
      onPressed: isUrlShareOnly
          ? null
          : () async {
              final state = ref.read(uploadProvider);
              if (state is! UploadFileSelected) return;
              final provider = state.providers[state.selectedProviderIndex];

              // Check if provider requires auth config
              if (provider.metadata.capabilities
                  .contains(ProviderCapability.requiresAuth)) {
                final configured = await isProviderConfigured(ref, provider);
                if (!configured) {
                  if (context.mounted) {
                    showProviderConfigDialog(context, ref, provider);
                  }
                  return;
                }
              }

              if (!context.mounted) return;
              final proceed =
                  await checkInsecureWarning(context, provider, ref);
              if (!proceed) return;
              notifier.uploadSelected();
            },
      icon: const Icon(Icons.cloud_upload),
      label: Text(l10n.upload),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}

class _FileSelectedButtons extends ConsumerStatefulWidget {
  final UploadNotifier notifier;
  const _FileSelectedButtons({required this.notifier});
  @override
  ConsumerState<_FileSelectedButtons> createState() =>
      _FileSelectedButtonsState();
}

class _FileSelectedButtonsState extends ConsumerState<_FileSelectedButtons> {
  final _msgController = TextEditingController();

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(uploadProvider);

    // Expiry picker — shown when the selected provider supports it
    final provider = state.providers.asMap()[state.selectedProviderIndex];
    final meta = provider?.metadata;
    final hasConfigurableExpiry =
        meta?.capabilities.contains(ProviderCapability.configurableExpiry) ==
            true;
    final expiryOptions = meta?.expiryOptions ?? [];
    final currentExpiry =
        state is UploadFileSelected ? state.selectedExpiry : null;

    if (state is UploadFileSelected) {
      // Pre-fill from global template on first load
      if (_msgController.text.isEmpty && state.messageText.isEmpty) {
        final globalTemplate =
            ref.read(globalMessageTemplateProvider).asData?.value ?? '';
        if (globalTemplate.isNotEmpty) {
          _msgController.text = globalTemplate;
          widget.notifier.setMessage(globalTemplate);
        }
      }
      // Sync controller with state messageText on provider change
      if (_msgController.text != state.messageText &&
          state.messageText.isNotEmpty) {
        _msgController.text = state.messageText;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasConfigurableExpiry && expiryOptions.isNotEmpty) ...[
          SegmentedButton<String>(
            segments: expiryOptions
                .map((opt) => ButtonSegment(
                    value: opt, label: Text(_expiryDisplayLabel(opt, l10n))))
                .toList(),
            selected: {currentExpiry ?? expiryOptions.first},
            onSelectionChanged: (v) => widget.notifier.setExpiry(v.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: _msgController,
          decoration: InputDecoration(
            labelText: 'Message',
            border: const OutlineInputBorder(),
            isDense: true,
            helperText: l10n.messageVariables('{url} {filename} {filesize}'),
          ),
          maxLines: 2,
          minLines: 1,
          onChanged: (v) => widget.notifier.setMessage(v),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _UploadButton(notifier: widget.notifier)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: l10n.clearSelection,
              onPressed: () => widget.notifier.clearSelection(),
            ),
          ],
        ),
      ],
    );
  }
}

/// Converts an API expiry value to a friendly display label.
/// [l10n] must be provided since this is called from widget code.
String _expiryDisplayLabel(String value, AppLocalizations l10n) {
  return switch (value) {
    '1h' => l10n.expiry1Hour,
    '24h' => l10n.expiry24Hours,
    '72h' => l10n.expiry3Days,
    _ => value,
  };
}

class _WebWarning extends StatelessWidget {
  const _WebWarning();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        child: Row(
          children: [
            Icon(Icons.warning_amber, size: 18, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
                child: Text(l10n.providerWebNotSupported,
                    style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontSize: 13))),
          ],
        ),
      ),
    );
  }
}

/// Shows a warning banner when the selected provider requires auth
/// configuration but hasn't been set up yet.
class _ProviderConfigStatus extends ConsumerStatefulWidget {
  final BaseUploader provider;

  const _ProviderConfigStatus({required this.provider});

  @override
  ConsumerState<_ProviderConfigStatus> createState() =>
      _ProviderConfigStatusState();
}

class _ProviderConfigStatusState extends ConsumerState<_ProviderConfigStatus> {
  int _configVersion = 0;

  @override
  Widget build(BuildContext context) {
    // Only show for providers that require auth
    if (!widget.provider.metadata.capabilities
        .contains(ProviderCapability.requiresAuth)) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Re-run the future when configVersion increments (after save).
    return FutureBuilder<bool>(
      key: ValueKey('config_${widget.provider.providerId}_$_configVersion'),
      future: isProviderConfigured(ref, widget.provider),
      builder: (context, snapshot) {
        final configured = snapshot.data ?? false;
        if (configured) return const SizedBox.shrink();

        return Card(
          color: Colors.orange.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.warning_amber,
                    size: 20, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.providerConfigNotConfigured(
                        widget.provider.providerName),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final saved = await showProviderConfigDialog(
                        context, ref, widget.provider);
                    if (saved && mounted) {
                      setState(() => _configVersion++);
                    }
                  },
                  icon: const Icon(Icons.settings, size: 16),
                  label: Text(l10n.providerConfigure),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

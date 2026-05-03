import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../providers/upload_provider.dart';

IconData _providerIcon(String id) => switch (id) {
      'httpbin' => Icons.science_outlined,
      'catbox' => Icons.folder_outlined,
      'tmpfilelink' => Icons.link,
      'uguu_uguu_se' || 'uguu_safe_uguu_se' => Icons.burst_mode_outlined,
      'freeimage_freeimage_host' => Icons.image_outlined,
      _ => Icons.cloud_upload,
    };

class UploadScreen extends ConsumerWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProviderDropdown(
            selectedIndex: uploadState.selectedProviderIndex,
            providers: providers,
            isUploading: uploadState is UploadInProgress,
            onChanged: (i) {
              if (i != null) notifier.setProvider(i);
            },
          ),
          if (provider != null) _ProviderInfo(provider: provider),
          if (webUnsupported) const _WebWarning(),
          switch (uploadState) {
            UploadFileSelected(fileName: final n, fileSizeBytes: final s, mimeType: final m, fileBytes: final b) =>
              _FilePreview(fileName: n, fileSize: s, mimeType: m, fileBytes: b, provider: provider),
            _ => const SizedBox.shrink(),
          },
          const SizedBox(height: 16),
          switch (uploadState) {
            UploadIdle() => _PickButton(notifier: notifier),
            UploadFileSelected() => _UploadButton(notifier: notifier),
            _ => const SizedBox.shrink(),
          },
          switch (uploadState) {
            UploadInProgress(progress: final p, speedLabel: final sp, sentBytes: final sb, totalBytes: final tb) => _ProgressSection(
                progress: p,
                speedLabel: sp,
                sentBytes: sb,
                totalBytes: tb,
                onCancel: notifier.cancelUpload,
              ),
            UploadStarting() => _ProgressSection(
                progress: null,
                onCancel: notifier.cancelUpload,
              ),
            UploadCompleted(errorMessage: final e, lastResult: final _) when e != null => _ErrorBanner(error: e),
            UploadCompleted(lastResult: final r) => _ResultBanner(url: r.url),
            _ => const SizedBox.shrink(),
          },
          const SizedBox(height: 16),
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
          final isHovering = candidateData.isNotEmpty;
          return Stack(
            children: [
              content,
              if (isHovering)
                Positioned.fill(
                  child: Container(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_upload, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Text('Drop file to upload',
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
    return content;
  }
}

class _ProviderDropdown extends StatelessWidget {
  final int selectedIndex;
  final List<dynamic> providers;
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
    return DropdownButton<int>(
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
              Icon(_providerIcon(p.providerId), size: 20,
                color: online ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor),
              const SizedBox(width: 8),
              Text(p.providerName,
                style: online ? null : TextStyle(color: Theme.of(context).disabledColor)),
              _metadataBadges(p.metadata),
            ],
          ),
        );
      }).toList(),
    );
  }
}

Widget _metadataBadges(dynamic meta) {
  final chips = <Widget>[];

  if (meta.fileSizeLabel is String && (meta.fileSizeLabel as String).isNotEmpty) {
    chips.add(_buildBadge(meta.fileSizeLabel as String));
  }
  if (meta.allowedMimeTypes != null) {
    chips.add(_buildBadge(meta.mimeTypeLabel as String));
  }
  if (meta.expiryInfo is String && (meta.expiryInfo as String).isNotEmpty) {
    chips.add(_buildBadge(meta.expiryInfo as String));
  }

  if (chips.isEmpty) return const SizedBox.shrink();

  return Row(mainAxisSize: MainAxisSize.min, children: chips);
}

Widget _buildBadge(String label) {
  return Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.blue)),
    ),
  );
}

class _ProviderInfo extends StatelessWidget {
  final dynamic provider;
  const _ProviderInfo({required this.provider});

  @override
  Widget build(BuildContext context) {
    final meta = provider.metadata;
    final infos = <String>[];

    if (meta.fileSizeLabel is String && (meta.fileSizeLabel as String).isNotEmpty) {
      infos.add('Max file size: ${meta.fileSizeLabel}');
    }
    if (meta.expiryInfo is String && (meta.expiryInfo as String).isNotEmpty) {
      infos.add(meta.expiryInfo as String);
    }
    if (meta.allowedMimeTypes != null) {
      infos.add(meta.mimeTypeLabel as String);
    }

    if (infos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: infos.map((info) => Text(info,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        )).toList(),
      ),
    );
  }
}

class _PickButton extends ConsumerWidget {
  final dynamic notifier;
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
  final dynamic notifier;
  const _UploadButton({required this.notifier});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ElevatedButton.icon(
      onPressed: () => notifier.uploadSelected(),
      icon: const Icon(Icons.cloud_upload),
      label: Text(l10n.upload),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}

class _FilePreview extends StatelessWidget {
  final String fileName;
  final int fileSize;
  final String? mimeType;
  final Uint8List? fileBytes;
  final dynamic provider;

  const _FilePreview({
    required this.fileName,
    required this.fileSize,
    this.mimeType,
    this.fileBytes,
    this.provider,
  });

  bool get _isImage {
    final mime = mimeType ?? '';
    return mime.startsWith('image/');
  }

  @override
  Widget build(BuildContext context) {
    final warnings = _buildWarnings();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fileBytes != null && _isImage) ...[
                // Image preview
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Image.memory(
                          fileBytes!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ] else if (_isImage) ...[
                // Image without bytes (shouldn't happen, but fallback)
                const Center(child: Icon(Icons.image_outlined, size: 80, color: Colors.grey)),
                const SizedBox(height: 12),
              ] else ...[
                // Non-image file icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.insert_drive_file, size: 48, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // File info row
              Row(
                children: [
                  Expanded(
                    child: Text(fileName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(formatSize(fileSize),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              if (mimeType != null) ...[
                const SizedBox(height: 4),
                Text(mimeType!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                ...warnings,
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildWarnings() {
    final warnings = <Widget>[];
    final meta = provider?.metadata;

    if (meta?.allowedMimeTypes != null && mimeType != null) {
      if (!meta.allowsMimeType(mimeType)) {
        warnings.add(_warningRow('Provider only accepts: ${meta.mimeTypeLabel}'));
      }
    }

    if (meta?.maxFileSizeBytes != null && fileSize > meta.maxFileSizeBytes) {
      warnings.add(_warningRow('File exceeds ${meta.fileSizeLabel} limit'));
    }

    return warnings;
  }

  Widget _warningRow(String msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 6),
          Expanded(
            child: Text(msg,
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebWarning extends StatelessWidget {
  const _WebWarning();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.orange.shade100,
        child: Row(
          children: [
            const Icon(Icons.warning_amber, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.providerWebNotSupported,
              style: TextStyle(color: Colors.orange.shade900, fontSize: 13))),
          ],
        ),
      ),
    );
  }
}

class _ProgressSection extends StatefulWidget {
  final double? progress;
  final String speedLabel;
  final int sentBytes;
  final int totalBytes;
  final VoidCallback onCancel;

  const _ProgressSection({
    this.progress,
    this.speedLabel = '',
    this.sentBytes = 0,
    this.totalBytes = 0,
    required this.onCancel,
  });

  @override
  State<_ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<_ProgressSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _anim = Tween<double>(begin: 0, end: widget.progress ?? 0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _animCtrl.forward();
  }

  @override
  void didUpdateWidget(_ProgressSection old) {
    super.didUpdateWidget(old);
    final target = widget.progress ?? 0;
    _anim = Tween<double>(begin: _anim.value, end: target).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _animCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pct = ((widget.progress ?? 0) * 100).toStringAsFixed(0);
    final hasData = widget.sentBytes > 0;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: percentage + speed
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$pct%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (hasData && widget.speedLabel.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.speed, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(widget.speedLabel,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Animated progress bar
              AnimatedBuilder(
                animation: _anim,
                builder: (context, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _anim.value,
                      minHeight: 8,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              // Bytes counter
              if (hasData)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatSize(widget.sentBytes),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(formatSize(widget.totalBytes),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton.icon(
                  onPressed: widget.onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(l10n.cancelUpload),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;

  const _ErrorBanner({required this.error});

  static String _translate(AppLocalizations l10n, String key) {
    return switch (key) {
      'genericError' => l10n.genericError,
      'errorSessionExpired' => l10n.errorSessionExpired,
      'errorFileTooLarge' => l10n.errorFileTooLarge,
      'errorConnectionFailed' => l10n.errorConnectionFailed,
      'uploadCancelled' => l10n.uploadCancelled,
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.red.shade100,
        child: Row(
          children: [
            Text('${l10n.error}: ',
              style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600)),
            Expanded(child: Text(_translate(l10n, error),
              style: TextStyle(color: Colors.red.shade800))),
          ],
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final String? url;

  const _ResultBanner({this.url});

  @override
  Widget build(BuildContext context) {
    final success = url != null;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(success ? l10n.uploadComplete : l10n.uploadFailed),
            ],
          ),
          if (url != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SelectableText(url!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  onPressed: () async {
                    final uri = Uri.tryParse(url!);
                    if (uri != null) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  tooltip: l10n.openInBrowser,
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.urlCopiedToClipboard)),
                    );
                  },
                  tooltip: l10n.urlCopiedToClipboard,
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 18),
                  onPressed: () {
                    if (url != null) {
                      SharePlus.instance.share(ShareParams(text: url!));
                    }
                  },
                  tooltip: l10n.shareUrl,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

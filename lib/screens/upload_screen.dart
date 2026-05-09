import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../core/format.dart';
import '../core/interfaces/uploader.dart';
import '../core/metadata_badges.dart';
import '../core/models/upload_result.dart';
import '../core/share_message_dialog.dart';
import '../core/version.dart';
import '../l10n/app_localizations.dart';
import '../providers/upload_provider.dart';
import '../screens/settings_screen.dart';
import '../widgets/image_crop_overlay.dart';

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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AppDescription(),
            const SizedBox(height: 16),
            _ProviderDropdown(
              selectedIndex: uploadState.selectedProviderIndex,
              providers: providers,
              isUploading: uploadState is UploadInProgress,
              onChanged: (i) {
                if (i != null) notifier.setProvider(i);
              },
            ),
            if (provider != null) ...[
              const SizedBox(height: 8),
              _ProviderInfo(provider: provider),
            ],
            if (provider != null) ...[
              const SizedBox(height: 8),
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
                  child: _FilePreview(
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
                _FilePreview(
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
                _FilePreview(
                    fileName: fn,
                    fileSize: fs,
                    mimeType: m,
                    fileBytes: fb,
                    provider: provider,
                    notifier: notifier),
              _ => const SizedBox.shrink(),
            },
            const SizedBox(height: 12),
            switch (uploadState) {
              UploadIdle() => _PickButton(notifier: notifier),
              UploadFileSelected() => _FileSelectedButtons(notifier: notifier),
              _ => const SizedBox.shrink(),
            },
            switch (uploadState) {
              UploadInProgress(
                progress: final p,
                speedLabel: final sp,
                sentBytes: final sb,
                totalBytes: final tb
              ) =>
                _ProgressSection(
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
                _ResultBanner(
                  url: r.url,
                  errorMessage: e,
                  fileName: fn,
                  fileSizeBytes: fs,
                  mimeType: m,
                  fileBytes: fb,
                  provider: provider,
                  lastResult: r,
                  onRetry: e != null ? () => notifier.uploadSelected() : null,
                  onCancel: e != null ? () => notifier.clearSelection() : null,
                ),
              _ => const SizedBox.shrink(),
            },
            const SizedBox(height: 8),
          ],
        ),
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
              content,
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
    return content;
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
      message: selectedProvider?.providerName ?? '',
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
                Icon(
                  _providerIcon(p.providerId),
                  size: 20,
                  color: online
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).disabledColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                  p.providerName,
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
                  Text(
                    l10n.maxFileSize(formatSize(meta.maxFileSizeBytes!)),
                    style: Theme.of(context).textTheme.bodySmall,
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
                      l10n.acceptedFiles(meta.mimeTypeLabel),
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
                  Text(
                    l10n.expiryInfo(meta.expiryInfo!),
                    style: Theme.of(context).textTheme.bodySmall,
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

class _AppDescription extends StatelessWidget {
  const _AppDescription();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 36,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
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
    return ElevatedButton.icon(
      onPressed: () async {
        final state = ref.read(uploadProvider);
        if (state is! UploadFileSelected) return;
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

class _FileSelectedButtons extends ConsumerWidget {
  final UploadNotifier notifier;
  const _FileSelectedButtons({required this.notifier});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uploadProvider);
    final mimeType = state is UploadFileSelected ? state.mimeType : null;
    final quality = state is UploadFileSelected ? state.quality : 0;
    final showQuality = mimeType?.startsWith('image/') == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showQuality) ...[
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                  value: 0,
                  label: Text('Original'),
                  icon: Icon(Icons.high_quality, size: 16)),
              ButtonSegment(
                  value: 1,
                  label: Text('Medium'),
                  icon: Icon(Icons.photo_size_select_large, size: 16)),
              ButtonSegment(
                  value: 2,
                  label: Text('Low'),
                  icon: Icon(Icons.photo_size_select_small, size: 16)),
            ],
            selected: {quality},
            onSelectionChanged: (v) => notifier.setQuality(v.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(child: _UploadButton(notifier: notifier)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Clear selection',
              onPressed: () => notifier.clearSelection(),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilePreview extends StatefulWidget {
  final String fileName;
  final int fileSize;
  final String? mimeType;
  final Uint8List? fileBytes;
  final BaseUploader? provider;
  final UploadNotifier notifier;

  const _FilePreview({
    required this.fileName,
    required this.fileSize,
    this.mimeType,
    this.fileBytes,
    this.provider,
    required this.notifier,
  });

  @override
  State<_FilePreview> createState() => _FilePreviewState();
}

class _FilePreviewState extends State<_FilePreview> {
  bool _isCropMode = false;
  bool _hasCropped = false;
  int _cropImageWidth = 0;
  int _cropImageHeight = 0;

  bool get _isImage {
    final mime = widget.mimeType ?? '';
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
              if (widget.fileBytes != null && _isImage) ...[
                _buildImagePreview(),
                const SizedBox(height: 12),
              ] else if (_isImage) ...[
                // Image without bytes (shouldn't happen, but fallback)
                const Center(
                    child: Icon(Icons.image_outlined,
                        size: 80, color: Colors.grey)),
                const SizedBox(height: 12),
              ] else ...[
                // Non-image file icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.insert_drive_file,
                        size: 48, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // File info row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.fileName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      formatSize(widget.fileSize),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              if (widget.mimeType != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.mimeType!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
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

  Widget _buildImagePreview() {
    if (_isCropMode) {
      return Center(
        child: SizedBox(
          width: double.infinity,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ImageCropOverlay(
              imageBytes: widget.fileBytes!,
              imageWidth: _cropImageWidth,
              imageHeight: _cropImageHeight,
              onConfirm: _onCropConfirm,
              onCancel: () => setState(() => _isCropMode = false),
            ),
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Image
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Image.memory(
                  widget.fileBytes!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, size: 64),
                ),
              ),
            ),
          ),
        ),
        // Crop / Reset button
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: Icon(_hasCropped ? Icons.restore : Icons.crop),
            tooltip: _hasCropped ? 'Reset crop' : 'Crop',
            onPressed: _hasCropped
                ? () {
                    widget.notifier.resetCrop();
                    setState(() => _hasCropped = false);
                  }
                : _enterCropMode,
            style: IconButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
          ),
        ),
      ],
    );
  }

  void _enterCropMode() {
    if (widget.fileBytes == null) return;
    final decoded = img.decodeImage(widget.fileBytes!);
    if (decoded == null) return;
    _cropImageWidth = decoded.width;
    _cropImageHeight = decoded.height;
    setState(() => _isCropMode = true);
  }

  void _onCropConfirm(Rect cropRect) {
    if (widget.fileBytes == null) return;
    final src = img.decodeImage(widget.fileBytes!);
    if (src == null) return;

    // Perform the crop
    final cropped = img.copyCrop(
      src,
      x: cropRect.left.toInt(),
      y: cropRect.top.toInt(),
      width: cropRect.width.toInt(),
      height: cropRect.height.toInt(),
    );

    // Encode as JPEG
    final outBytes = img.encodeJpg(cropped, quality: 90);

    // Push to provider
    widget.notifier.applyCrop(outBytes);

    setState(() {
      _isCropMode = false;
      _hasCropped = true;
    });
  }

  List<Widget> _buildWarnings() {
    final warnings = <Widget>[];
    final p = widget.provider;
    if (p == null) return warnings;
    final meta = p.metadata;

    if (meta.allowedMimeTypes != null && widget.mimeType != null) {
      if (!meta.allowsMimeType(widget.mimeType!)) {
        warnings
            .add(_warningRow('Provider only accepts: ${meta.mimeTypeLabel}'));
      }
    }

    if (meta.maxFileSizeBytes != null &&
        widget.fileSize > meta.maxFileSizeBytes!) {
      warnings.add(_warningRow('File exceeds ${meta.fileSizeLabel} limit'));
    }

    return warnings;
  }

  Widget _warningRow(String msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              msg,
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
            Expanded(
                child: Text(l10n.providerWebNotSupported,
                    style: TextStyle(
                        color: Colors.orange.shade900, fontSize: 13))),
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
    if (old.progress != widget.progress) {
      final target = widget.progress ?? 0;
      _anim = Tween<double>(begin: _anim.value, end: target).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
      );
      _animCtrl.forward(from: 0);
    }
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
                  Text(
                    '$pct%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  if (hasData && widget.speedLabel.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.speed,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          widget.speedLabel,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                    Text(
                      formatSize(widget.sentBytes),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    Text(
                      formatSize(widget.totalBytes),
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

class _ResultBanner extends StatefulWidget {
  final String? url;
  final String? errorMessage;
  final String? fileName;
  final int fileSizeBytes;
  final String? mimeType;
  final Uint8List? fileBytes;
  final BaseUploader? provider;
  final UploadResult? lastResult;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const _ResultBanner({
    this.url,
    this.errorMessage,
    this.fileName,
    this.fileSizeBytes = 0,
    this.mimeType,
    this.fileBytes,
    this.provider,
    this.lastResult,
    this.onRetry,
    this.onCancel,
  });

  @override
  State<_ResultBanner> createState() => _ResultBannerState();
}

class _ResultBannerState extends State<_ResultBanner> {
  void _showDebugInfo(BuildContext context) {
    final buffer = StringBuffer();
    final result = widget.lastResult;
    final p = widget.provider;

    // Provider info
    buffer.writeln('=== PROVIDER ===');
    buffer.writeln('Name: ${p?.providerName ?? "unknown"}');
    buffer.writeln('ID: ${p?.providerId ?? "?"}');

    // File info
    buffer.writeln('=== FILE ===');
    buffer.writeln('Name: ${widget.fileName ?? "none"}');
    buffer.writeln(
        'Size: ${formatSize(widget.fileSizeBytes)} (${widget.fileSizeBytes} bytes)');
    buffer.writeln('MIME: ${widget.mimeType ?? "unknown"}');

    // Error details
    buffer.writeln('=== ERROR ===');
    buffer.writeln('Message: ${widget.errorMessage ?? "none"}');
    buffer.writeln('Raw Error: ${result?.rawError ?? "none"}');
    buffer.writeln('Status Code: ${result?.statusCode ?? "none"}');
    buffer.writeln(
        'Timestamp: ${result?.completedAt.toIso8601String() ?? "none"}');
    if (result?.stackTrace != null) {
      buffer.writeln('Stack Trace: ${result!.stackTrace}');
    }

    // URL info
    buffer.writeln('=== RESPONSE ===');
    buffer.writeln('URL: ${widget.url ?? "none"}');
    buffer.writeln('Success: ${result?.success ?? false}');

    // Build info
    buffer.writeln('=== BUILD ===');
    buffer.writeln('Git Hash: $gitHash');
    buffer.writeln('Platform: ${Platform.operatingSystem}');
    buffer.writeln('Platform Version: ${Platform.operatingSystemVersion}');

    final text = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report, size: 18),
            SizedBox(width: 8),
            Text('Debug Info'),
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

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorMessage != null;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result row
          Row(
            children: [
              Icon(hasError ? Icons.error : Icons.check_circle,
                  color: hasError ? Colors.red : Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(hasError ? l10n.uploadFailed : l10n.uploadComplete),
            ],
          ),
          if (hasError && widget.errorMessage != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(widget.errorMessage!,
                      style:
                          TextStyle(color: Colors.red.shade700, fontSize: 13)),
                ),
                IconButton(
                  icon: const Icon(Icons.bug_report, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Debug info',
                  onPressed: () => _showDebugInfo(context),
                ),
              ],
            ),
          ],
          if (widget.url != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    widget.url!,
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
                    final uri = Uri.tryParse(widget.url!);
                    if (uri != null) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  tooltip: l10n.openInBrowser,
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.url!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.urlCopiedToClipboard)),
                    );
                  },
                  tooltip: l10n.urlCopiedToClipboard,
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 18),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => ShareMessageDialog(
                        url: widget.url!,
                        providerName: widget.provider?.providerName,
                        fileName: widget.fileName,
                      ),
                    );
                  },
                  tooltip: l10n.shareUrl,
                ),
              ],
            ),
          ],
          // Retry button on error
          if (hasError) ...[
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onRetry != null)
                    ElevatedButton.icon(
                      onPressed: widget.onRetry,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(l10n.retry),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade100,
                        foregroundColor: Colors.orange.shade800,
                      ),
                    ),
                  if (widget.onCancel != null) ...[
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: widget.onCancel,
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(l10n.cancel),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

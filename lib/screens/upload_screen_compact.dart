import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/semantics.dart' show TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/interfaces/uploader.dart';
import '../core/metadata_badges.dart';
import '../l10n/app_localizations.dart';
import '../providers/upload_provider.dart';

/// Compact variant of the upload screen.
class CompactUploadLayout extends ConsumerWidget {
  const CompactUploadLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(uploadProvider);
    final notifier = ref.read(uploadProvider.notifier);
    final providers = uploadState.providers;
    final selectedIndex = uploadState.selectedProviderIndex;
    final provider = selectedIndex < providers.length ? providers[selectedIndex] : null;
    final l10n = AppLocalizations.of(context);
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows);

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompactProviderSelector(
            selectedIndex: selectedIndex,
            providers: providers,
            isUploading: uploadState is UploadInProgress,
            onChanged: (i) {
              if (i != null) notifier.setProvider(i);
            },
          ),
          if (provider != null) ...[
            const SizedBox(height: 8),
            metadataBadges(provider.metadata),
          ],
          if (uploadState is UploadFileSelected || uploadState is UploadInProgress || uploadState is UploadCompleted) ...[
            const SizedBox(height: 12),
            _CompactFilePreview(uploadState: uploadState, provider: provider),
          ],
          const SizedBox(height: 12),
          switch (uploadState) {
            UploadIdle() => ElevatedButton(
                onPressed: () => notifier.pickAndUpload(),
                child: Text(l10n.pickAndUpload),
              ),
            UploadFileSelected() => ElevatedButton.icon(
                onPressed: () => notifier.uploadSelected(),
                icon: const Icon(Icons.cloud_upload),
                label: Text(l10n.upload),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            _ => const SizedBox.shrink(),
          },
          if (uploadState is UploadInProgress) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: uploadState.progress),
            if (uploadState.speedLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(uploadState.speedLabel,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
          if (uploadState is UploadCompleted) ...[
            const SizedBox(height: 8),
            _CompactResultBanner(uploadState: uploadState, provider: provider),
          ],
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
              notifier.uploadFromFile(uri.path, null);
              break;
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
                            Text(l10n.dropFileToUpload,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                )),
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

class _CompactProviderSelector extends StatelessWidget {
  final int selectedIndex;
  final List<BaseUploader> providers;
  final bool isUploading;
  final ValueChanged<int?> onChanged;

  const _CompactProviderSelector({
    required this.selectedIndex,
    required this.providers,
    required this.isUploading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: providers.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final isSelected = i == selectedIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              onSelected: isUploading ? null : (v) => onChanged(i),
              avatar: Icon(
                _providerIcon(p.providerId),
                size: 16,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.primary,
              ),
              label: Text(p.providerName),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _providerIcon(String id) => switch (id) {
        'httpbin' => Icons.science_outlined,
        'catbox' => Icons.folder_outlined,
        'tmpfilelink' => Icons.link,
        'uguu_uguu_se' || 'uguu_safe_uguu_se' => Icons.burst_mode_outlined,
        'freeimage_freeimage_host' => Icons.image_outlined,
        _ => Icons.cloud_upload,
      };
}

class _CompactFilePreview extends StatelessWidget {
  final UploadState uploadState;
  final BaseUploader? provider;
  const _CompactFilePreview({required this.uploadState, required this.provider});

  String? get _fileName => switch (uploadState) {
        UploadFileSelected(fileName: final n) => n,
        UploadInProgress(fileName: final n) => n,
        UploadCompleted(fileName: final n) => n,
        _ => null,
      };

  int get _fileSizeBytes => switch (uploadState) {
        UploadFileSelected(fileSizeBytes: final s) => s,
        UploadInProgress(fileSizeBytes: final s) => s,
        UploadCompleted(fileSizeBytes: final s) => s,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    final fileName = _fileName;
    if (fileName == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fileName,
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis),
                  Text('${(_fileSizeBytes / 1024).toStringAsFixed(1)} KB',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactResultBanner extends StatelessWidget {
  final UploadCompleted uploadState;
  final BaseUploader? provider;
  const _CompactResultBanner({required this.uploadState, required this.provider});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasError = uploadState.errorMessage != null;
    return Card(
      color: hasError ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(hasError ? Icons.error : Icons.check_circle,
                color: hasError ? Colors.red : Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasError ? uploadState.errorMessage! : l10n.uploadComplete,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

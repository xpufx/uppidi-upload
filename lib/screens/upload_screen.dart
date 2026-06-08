import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config_provider.dart';
import '../core/format.dart';
import '../core/insecure_upload_warning.dart';
import '../core/interfaces/uploader.dart';
import '../core/logging/log.dart';
import '../core/models/provider_instance.dart';
import '../core/models/provider_metadata.dart';
import '../core/provider_config_sheet.dart';
import '../core/models/upload_result.dart';
import '../core/settings_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/upload_provider.dart';
import '../widgets/file_preview.dart';
import '../widgets/provider_favicon.dart';
import '../widgets/result_banner.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isHovering = false;
  late final AnimationController _staggerController;
  late final Animation<double> _providerCardAnim;
  late final Animation<double> _infoCardAnim;
  late final Animation<double> _contentAnim;
  final _log = Log('UploadScreen');
  Type? _lastStateType;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _providerCardAnim = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
    _infoCardAnim = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.15, 0.45, curve: Curves.easeOut),
    );
    _contentAnim = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _restartStagger() {
    _staggerController.reset();
    _staggerController.forward();
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
    final accentColor =
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.7);

    ref.listen(uploadProvider, (prev, next) {
      if (prev.runtimeType != next.runtimeType) {
        if (prev is UploadInProgress && next is UploadCompleted) return;
        _restartStagger();
      }
    });

    if (uploadState.runtimeType != _lastStateType) {
      _log.debug(
          'state: ${uploadState.runtimeType} provider=${provider?.providerId}');
      _lastStateType = uploadState.runtimeType;
    }

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
              FadeTransition(
                opacity: _providerCardAnim,
                child: _ProviderSelectionCard(
                  selectedIndex: uploadState.selectedProviderIndex,
                  providers: providers,
                  isUploading: uploadState is UploadInProgress,
                  hasFile: uploadState is! UploadIdle,
                  accentColor: accentColor,
                  onChanged: (i) {
                    if (i != null) {
                      notifier.setProvider(i);
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _infoCardAnim,
                child: Column(
                  children: [
                    if (webUnsupported) const _WebWarningCard(),
                    if (provider != null &&
                        provider.metadata.capabilities.contains(
                          ProviderCapability.requiresAuth,
                        ))
                      _ProviderConfigStatusCard(
                        provider: provider,
                        accentColor: accentColor,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _contentAnim,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.05),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: switch (uploadState) {
                    UploadIdle() => _EmptyUploadState(
                        key: const ValueKey('idle'),
                        onPick: notifier.pickAndUpload,
                        onPaste: () async {
                          _log.debug('paste triggered');
                          final img = await Pasteboard.image;
                          if (img != null) {
                            notifier.uploadFromBytes(img, 'clipboard.png',
                                mimeType: 'image/png');
                          }
                        },
                      ),
                    UploadFileSelected(
                      fileName: final n,
                      fileSizeBytes: final s,
                      mimeType: final m,
                      fileBytes: final b,
                    ) =>
                      Column(
                        key: const ValueKey('file-selected'),
                        children: [
                          Dismissible(
                            key: const ValueKey('file-preview'),
                            direction: DismissDirection.horizontal,
                            onDismissed: (_) => notifier.clearSelection(),
                            child: _FilePreviewCard(
                              fileName: n,
                              fileSize: s,
                              mimeType: m,
                              fileBytes: b,
                              provider: provider,
                              notifier: notifier,
                              accentColor: accentColor,
                            ),
                          ),
                        ],
                      ),
                    UploadInProgress(
                      fileBytes: final fb,
                      fileName: final fn,
                      fileSizeBytes: final fs,
                      mimeType: final m,
                      progress: final p,
                      speedLabel: final sp,
                      sentBytes: final sb,
                      totalBytes: final tb,
                    ) =>
                      Column(
                        key: const ValueKey('upload-progress'),
                        children: [
                          Stack(
                            children: [
                              _FilePreviewCard(
                                fileName: fn,
                                fileSize: fs,
                                mimeType: m,
                                fileBytes: fb,
                                provider: provider,
                                notifier: notifier,
                                accentColor: accentColor,
                              ),
                              _ProgressOverlay(
                                progress: p,
                                speedLabel: sp,
                                sentBytes: sb,
                                totalBytes: tb,
                                onCancel: notifier.cancelUpload,
                              ),
                            ],
                          ),
                        ],
                      ),
                    UploadCompleted(
                      lastResult: final r,
                      errorMessage: final e,
                      fileName: final fn,
                      fileSizeBytes: final fs,
                      mimeType: final m,
                      fileBytes: final fb,
                    ) =>
                      Column(
                        key: const ValueKey('upload-completed'),
                        children: [
                          _FilePreviewCard(
                            fileName: fn,
                            fileSize: fs,
                            mimeType: m,
                            fileBytes: fb,
                            provider: provider,
                            notifier: notifier,
                            accentColor: accentColor,
                          ),
                          const SizedBox(height: 16),
                          _ResultBannerCard(
                            url: r.url,
                            errorMessage: e,
                            fileName: fn,
                            fileSizeBytes: fs,
                            mimeType: m,
                            fileBytes: fb,
                            provider: provider,
                            lastResult: r,
                            accentColor: accentColor,
                            onRetry: e != null
                                ? () async {
                                    final proceed = await checkInsecureWarning(
                                      context,
                                      provider!,
                                      ref,
                                    );
                                    if (proceed) notifier.uploadSelected();
                                  }
                                : null,
                            onCancel: () => notifier.clearSelection(),
                          ),
                        ],
                      ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final bottomBar = _BottomActionBar(notifier: notifier);

    final screen = SafeArea(
      child: Column(
        children: [
          Expanded(child: scrollBody),
          bottomBar,
        ],
      ),
    );

    if (!kIsWeb) {
      return DropTarget(
        onDragEntered: (_) => setState(() => _isHovering = true),
        onDragExited: (_) => setState(() => _isHovering = false),
        onDragDone: (details) {
          setState(() => _isHovering = false);
          final file = details.files.first;
          _log.info('drop: ${file.path} (${file.mimeType})');
          notifier.uploadFromFile(file.path, file.mimeType);
        },
        child: Container(
          decoration: _isHovering
              ? BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: screen,
        ),
      );
    }
    return screen;
  }
}

/// Provider selection dropdown wrapped in a card with hover animation.
class _ProviderSelectionCard extends ConsumerStatefulWidget {
  final int? selectedIndex;
  final List<BaseUploader> providers;
  final bool isUploading;
  final bool hasFile;
  final Color? accentColor;
  final void Function(int?)? onChanged;
  const _ProviderSelectionCard({
    required this.selectedIndex,
    required this.providers,
    required this.isUploading,
    required this.hasFile,
    this.accentColor,
    required this.onChanged,
  });

  @override
  ConsumerState<_ProviderSelectionCard> createState() =>
      _ProviderSelectionCardState();
}

class _ProviderSelectionCardState
    extends ConsumerState<_ProviderSelectionCard> {
  bool _isHovering = false;
  bool _showInfo = false;
  Timer? _infoTimer;

  @override
  void initState() {
    super.initState();
    _startInfoTimer();
  }

  @override
  void didUpdateWidget(covariant _ProviderSelectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.hasFile && widget.hasFile && _showInfo) {
      _dismissInfo();
    }
  }

  @override
  void dispose() {
    _infoTimer?.cancel();
    super.dispose();
  }

  void _startInfoTimer() {
    _infoTimer?.cancel();
    _infoTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && _showInfo) {
        setState(() => _showInfo = false);
      }
    });
  }

  void _dismissInfo() {
    _infoTimer?.cancel();
    setState(() => _showInfo = false);
  }

  void _toggleInfo() {
    setState(() => _showInfo = !_showInfo);
    if (!_showInfo) {
      _infoTimer?.cancel();
    } else {
      _startInfoTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = widget.selectedIndex != null &&
            widget.selectedIndex! < widget.providers.length
        ? widget.providers[widget.selectedIndex!]
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: Card(
        elevation: _isHovering ? 4 : 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.accentColor != null)
              Container(height: 3, color: widget.accentColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        popupMenuTheme: PopupMenuThemeData(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      child: DropdownButtonFormField<int?>(
                        key: ValueKey('provider_${widget.selectedIndex}'),
                        isDense: true,
                        isExpanded: true,
                        initialValue: widget.selectedIndex,
                        disabledHint: Text(l10n.noProvidersAvailable),
                        decoration: InputDecoration(
                          labelText: l10n.providersSection,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          for (final p in widget.providers.asMap().entries)
                            DropdownMenuItem<int>(
                              value: p.key,
                              child: Row(
                                children: [
                                  ProviderFavicon(
                                    providerId: p.value.providerId,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      p.value is ProviderInstance
                                          ? (p.value as ProviderInstance)
                                              .displayName
                                          : p.value.providerName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        onChanged: widget.isUploading ? null : widget.onChanged,
                      ),
                    ),
                  ),
                  if (provider != null) ...[
                    IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _showInfo ? Icons.info : Icons.info_outline,
                          key: ValueKey(_showInfo),
                          size: 20,
                        ),
                      ),
                      tooltip: l10n.providerInfoTitle,
                      onPressed: _toggleInfo,
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: l10n.providerConfigure,
                      onPressed: () =>
                          showProviderConfigDialog(context, ref, provider),
                    ),
                  ],
                ],
              ),
            ),
            if (provider != null)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _showInfo
                    ? _ProviderInfoCard(provider: provider)
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}

/// Provider info card with metadata badges and color-coded capability rows.
class _ProviderInfoCard extends StatelessWidget {
  final BaseUploader provider;

  const _ProviderInfoCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final meta = provider.metadata;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.providerInfoTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.folder_open,
            label: l10n.navProviders,
            value: provider.providerName,
          ),
          if (meta.maxFileSizeBytes != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.storage,
              label: l10n.maxFileSize(formatSize(meta.maxFileSizeBytes!)),
              value: formatSize(meta.maxFileSizeBytes!),
            ),
          ],
          if (meta.supportsDirectLink) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.link,
              label: l10n.supportsDirectLinks,
              value: l10n.enabled,
            ),
          ],
          if (meta.requiresAccount) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.person,
              label: l10n.requiresAccount,
              value: l10n.enabled,
            ),
          ],
          if (provider.instanceDescription != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.info_outline,
              label: '',
              value: provider.instanceDescription!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Provider config status card — shows a warning banner when auth is needed
/// but not yet configured.
class _ProviderConfigStatusCard extends ConsumerStatefulWidget {
  final BaseUploader provider;
  final Color? accentColor;
  const _ProviderConfigStatusCard({required this.provider, this.accentColor});

  @override
  ConsumerState<_ProviderConfigStatusCard> createState() =>
      _ProviderConfigStatusCardState();
}

class _ProviderConfigStatusCardState
    extends ConsumerState<_ProviderConfigStatusCard> {
  int _configVersion = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return FutureBuilder<bool>(
      key: ValueKey('config_${widget.provider.providerId}_$_configVersion'),
      future: isProviderConfigured(ref, widget.provider),
      builder: (context, snapshot) {
        final configured = snapshot.data ?? false;
        if (configured) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.orange.shade200),
            ),
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 20,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.providerConfigNotConfigured(
                        widget.provider.providerName,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final saved = await showProviderConfigDialog(
                        context,
                        ref,
                        widget.provider,
                      );
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
          ),
        );
      },
    );
  }
}

/// Web unsupported warning card.
class _WebWarningCard extends StatelessWidget {
  const _WebWarningCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.providerWebNotSupported,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// File preview wrapped in a card.
class _FilePreviewCard extends StatelessWidget {
  const _FilePreviewCard({
    required this.fileName,
    required this.fileSize,
    this.mimeType,
    this.fileBytes,
    this.provider,
    required this.notifier,
    this.accentColor,
  });

  final String? fileName;
  final int fileSize;
  final String? mimeType;
  final Uint8List? fileBytes;
  final BaseUploader? provider;
  final UploadNotifier notifier;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (accentColor != null) Container(height: 3, color: accentColor),
          FilePreview(
            fileName: fileName ?? '',
            fileSize: fileSize,
            mimeType: mimeType,
            fileBytes: fileBytes,
            provider: provider,
            notifier: notifier,
          ),
        ],
      ),
    );
  }
}

/// Result banner wrapped in a card.
class _ResultBannerCard extends StatelessWidget {
  const _ResultBannerCard({
    this.url,
    this.errorMessage,
    this.fileName,
    this.fileSizeBytes = 0,
    this.mimeType,
    this.fileBytes,
    this.provider,
    this.lastResult,
    this.onRetry,
    required this.onCancel,
    this.accentColor,
  });

  final String? url;
  final String? errorMessage;
  final String? fileName;
  final int fileSizeBytes;
  final String? mimeType;
  final Uint8List? fileBytes;
  final BaseUploader? provider;
  final UploadResult? lastResult;
  final VoidCallback? onRetry;
  final VoidCallback onCancel;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ResultBanner(
        url: url,
        errorMessage: errorMessage,
        fileName: fileName,
        fileSizeBytes: fileSizeBytes,
        mimeType: mimeType,
        fileBytes: fileBytes,
        provider: provider,
        lastResult: lastResult,
        onRetry: onRetry,
        onCancel: onCancel,
      ),
    );
  }
}

/// Bottom action bar with state-aware buttons.
class _BottomActionBar extends ConsumerWidget {
  final UploadNotifier notifier;
  const _BottomActionBar({required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final uploadState = ref.watch(uploadProvider);

    final Widget? bottomChild = switch (uploadState) {
      UploadFileSelected() => _FileSelectedBottomBar(notifier: notifier),
      UploadInProgress() => SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.cancel),
            label: Text(l10n.cancelUpload),
            onPressed: notifier.cancelUpload,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      _ => null,
    };

    if (bottomChild == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(top: false, child: bottomChild),
    );
  }
}

/// Bottom bar content for file-selected state — expiry picker, message,
/// upload and cancel buttons.
class _FileSelectedBottomBar extends ConsumerStatefulWidget {
  final UploadNotifier notifier;
  const _FileSelectedBottomBar({required this.notifier});

  @override
  ConsumerState<_FileSelectedBottomBar> createState() =>
      _FileSelectedBottomBarState();
}

class _FileSelectedBottomBarState
    extends ConsumerState<_FileSelectedBottomBar> {
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
    final provider = state.providers.asMap()[state.selectedProviderIndex];
    final meta = provider?.metadata;
    final hasConfigurableExpiry =
        meta?.capabilities.contains(ProviderCapability.configurableExpiry) ==
            true;
    final expiryOptions = meta?.expiryOptions ?? [];
    final currentExpiry =
        state is UploadFileSelected ? state.selectedExpiry : null;

    if (state is UploadFileSelected) {
      if (_msgController.text.isEmpty && state.messageText.isEmpty) {
        final globalTemplate =
            ref.read(globalMessageTemplateProvider).asData?.value ?? '';
        if (globalTemplate.isNotEmpty) {
          _msgController.text = globalTemplate;
          widget.notifier.setMessage(globalTemplate);
        }
      }
      if (_msgController.text != state.messageText) {
        _msgController.text = state.messageText;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasConfigurableExpiry && expiryOptions.isNotEmpty) ...[
          SegmentedButton<String>(
            segments: expiryOptions
                .map(
                  (opt) => ButtonSegment(
                    value: opt,
                    label: Text(_expiryDisplayLabel(opt, l10n)),
                  ),
                )
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
        if (provider?.supportsMessage == true) ...[
          TextFormField(
            controller: _msgController,
            decoration: InputDecoration(
              labelText: l10n.messageLabel,
              border: const OutlineInputBorder(),
              isDense: true,
              helperText: l10n.messageVariables('{url} {filename} {filesize}'),
            ),
            maxLines: 2,
            minLines: 1,
            onChanged: (v) => widget.notifier.setMessage(v),
          ),
          const SizedBox(height: 8),
        ],
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

/// Upload button with provider config + insecure warning checks.
class _UploadButton extends ConsumerWidget {
  final UploadNotifier notifier;
  const _UploadButton({required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(uploadProvider);
    final provider = state.providers.asMap()[state.selectedProviderIndex];
    final isLocal = provider?.providerId == 'local';
    var isUrlShareOnly = provider?.isUrlShareOnly ?? false;
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

              if (provider.metadata.capabilities.contains(
                ProviderCapability.requiresAuth,
              )) {
                final configured = await isProviderConfigured(ref, provider);
                if (!configured) {
                  if (context.mounted) {
                    showProviderConfigDialog(context, ref, provider);
                  }
                  return;
                }
              }

              if (provider.providerId == 'local' && !notifier.isModified) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No changes to save')),
                  );
                }
                return;
              }

              if (!context.mounted) return;
              final proceed = await checkInsecureWarning(
                context,
                provider,
                ref,
              );
              if (!proceed) return;
              notifier.uploadSelected();
            },
      icon: Icon(isLocal ? Icons.save : Icons.cloud_upload),
      label: Text(isLocal ? l10n.save : l10n.upload),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}

/// Helper widget for info rows.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

/// Converts an API expiry value to a friendly display label.
String _expiryDisplayLabel(String value, AppLocalizations l10n) {
  return switch (value) {
    '1h' => l10n.expiry1Hour,
    '24h' => l10n.expiry24Hours,
    '72h' => l10n.expiry3Days,
    _ => value,
  };
}

/// Progress overlay shown on top of the file preview during upload.
class _ProgressOverlay extends StatelessWidget {
  final double? progress;
  final String speedLabel;
  final int sentBytes;
  final int totalBytes;
  final VoidCallback onCancel;

  const _ProgressOverlay({
    this.progress,
    this.speedLabel = '',
    this.sentBytes = 0,
    this.totalBytes = 0,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pct = ((progress ?? 0) * 100).toStringAsFixed(0);
    final hasData = sentBytes > 0;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$pct%',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (hasData && speedLabel.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.speed,
                              size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            speedLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                if (hasData) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatSize(sentBytes),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white60),
                      ),
                      Text(
                        formatSize(totalBytes),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white60),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white70,
                    ),
                    label: Text(
                      l10n.cancelUpload,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state shown when no file is selected.
class _EmptyUploadState extends StatelessWidget {
  final VoidCallback onPick;
  final VoidCallback onPaste;

  const _EmptyUploadState({
    super.key,
    required this.onPick,
    required this.onPaste,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 72,
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.dropFileToUpload,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.upload_file),
              label: Text(l10n.chooseFile),
              style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onPaste,
              icon: const Icon(Icons.content_paste),
              label: Text(l10n.pasteFromClipboard),
            ),
          ],
        ),
      ),
    );
  }
}

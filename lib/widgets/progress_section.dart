import 'package:flutter/material.dart';

import '../core/format.dart';
import '../l10n/app_localizations.dart';

/// Shows upload progress: animated bar, percentage, speed, bytes, cancel.
class ProgressSection extends StatefulWidget {
  final double? progress;
  final String speedLabel;
  final int sentBytes;
  final int totalBytes;
  final VoidCallback onCancel;

  const ProgressSection({
    super.key,
    this.progress,
    this.speedLabel = '',
    this.sentBytes = 0,
    this.totalBytes = 0,
    required this.onCancel,
  });

  @override
  State<ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<ProgressSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _anim = Tween<double>(
      begin: 0,
      end: widget.progress ?? 0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(ProgressSection old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      final target = widget.progress ?? 0;
      _anim = Tween<double>(
        begin: _anim.value,
        end: target,
      ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
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
                        Icon(
                          Icons.speed,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
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
              AnimatedBuilder(
                animation: _anim,
                builder: (context, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _anim.value,
                      minHeight: 8,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.12),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
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

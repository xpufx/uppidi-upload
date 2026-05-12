import 'package:flutter/material.dart';

/// Displays a provider's favicon from bundled assets.
/// Looks up `assets/favicons/$providerId.png` and falls back to a generic icon.
class ProviderFavicon extends StatelessWidget {
  final String providerId;
  final double size;
  final Color? iconColor;

  const ProviderFavicon({
    super.key,
    required this.providerId,
    this.size = 20,
    this.iconColor,
  });

  IconData get _fallbackIcon {
    final id = providerId.toLowerCase();
    if (id.contains('httpbin')) return Icons.science_outlined;
    if (id.contains('catbox')) return Icons.folder_outlined;
    if (id.contains('tmpfilelink')) return Icons.link;
    if (id.contains('uguu')) return Icons.burst_mode_outlined;
    if (id.contains('freeimage')) return Icons.image_outlined;
    if (id.contains('temp') || id.contains('tempsh')) return Icons.cloud_upload;
    if (id.contains('litterbox')) return Icons.timer_outlined;
    if (id.contains('fileditch')) return Icons.cloud_upload;
    if (id.contains('frisk')) return Icons.shield_outlined;
    return Icons.cloud_upload;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        'assets/favicons/$providerId.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          _fallbackIcon,
          size: size,
          color: iconColor,
        ),
      ),
    );
  }
}

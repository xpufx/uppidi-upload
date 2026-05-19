import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'models/provider_metadata.dart';

/// Resolves a provider expiry info string to a localized value.
/// Providers store raw English keys like "expiry3Hours" in their metadata;
/// this maps them to the user's language.
String resolveExpiry(AppLocalizations l10n, String raw) {
  return switch (raw) {
    'Persistent (until bot token is revoked)' => l10n.expiryPersistent,
    'Indefinite (inactive >30d may delete)' => l10n.expiryIndefinite30d,
    '~1 day (extendable on re-upload)' => l10n.expiryOneDayExtendable,
    '1h / 12h / 24h / 72h' => l10n.expiryOptions1h12h24h72h,
    '3 hours' => l10n.expiry3Hours,
    '3 days' => l10n.expiry3Days,
    '7 days' => l10n.expiry7Days,
    _ => raw,
  };
}

/// Resolves a provider mime-type label to a localized value.
/// Dynamic labels like "PNG, JPG" pass through; known labels localize.
String resolveMimeLabel(AppLocalizations l10n, String raw) {
  return switch (raw) {
    'Images only' => l10n.mimeTypesImagesOnly,
    _ => raw,
  };
}

IconData mimeIcon(ProviderMetadata meta) {
  final types = meta.allowedMimeTypes;
  if (types == null || types.isEmpty) return Icons.insert_drive_file;
  final allImages = types.every((t) => t.startsWith('image/'));
  if (allImages) return Icons.image;
  final allVideo = types.every((t) => t.startsWith('video/'));
  if (allVideo) return Icons.video_file;
  return Icons.insert_drive_file;
}

Widget metadataBadges(ProviderMetadata meta) {
  final chips = <Widget>[];

  if (meta.fileSizeLabel.isNotEmpty) {
    chips.add(_buildBadge(meta.fileSizeLabel, icon: Icons.storage));
  }
  if (meta.allowedMimeTypes != null) {
    chips.add(_buildBadge(null, icon: mimeIcon(meta)));
  }
  if (meta.expiryInfo != null && meta.expiryInfo!.isNotEmpty) {
    // Expiry info is stored as raw keys; resolve via l10n at display time.
    // Badge has no l10n access — show raw value (the resolved version
    // appears in _ProviderInfo via resolveExpiry + l10n.expiryInfo).
    chips.add(_buildBadge(meta.expiryInfo!, icon: Icons.calendar_today));
  }

  if (chips.isEmpty) return const SizedBox.shrink();
  return Row(mainAxisSize: MainAxisSize.min, children: chips);
}

Widget _buildBadge(String? label, {IconData? icon}) {
  return Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 14, color: Colors.blue),
          if (label != null && label.isNotEmpty) ...[
            const SizedBox(width: 2),
            Flexible(
              child: Text(label,
                  style: const TextStyle(fontSize: 10, color: Colors.blue),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ],
      ),
    ),
  );
}

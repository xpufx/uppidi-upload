import 'package:flutter/material.dart';
import 'models/provider_metadata.dart';

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
          if (icon != null)
            Icon(icon, size: 14, color: Colors.blue),
          if (label != null && label.isNotEmpty) ...[
            const SizedBox(width: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.blue)),
          ],
        ],
      ),
    ),
  );
}

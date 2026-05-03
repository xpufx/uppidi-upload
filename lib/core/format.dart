String formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

String formatTime(DateTime dt, {
  required String justNow,
  required String Function(int minutes) minutesAgo,
  required String Function(int hours) hoursAgo,
}) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return justNow;
  if (diff.inHours < 1) return minutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return hoursAgo(diff.inHours);
  return '${dt.day}/${dt.month}/${dt.year}';
}

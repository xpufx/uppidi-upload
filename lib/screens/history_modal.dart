import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/history_screen.dart';
import 'modal_utils.dart';

/// Shows the upload history screen as an adaptive modal dialog.
void showHistoryModal(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  showAdaptiveModal(
    context: context,
    title: l10n.history,
    child: const HistoryScreen(),
  );
}

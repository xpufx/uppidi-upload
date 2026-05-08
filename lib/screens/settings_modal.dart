import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/settings_screen.dart';
import 'modal_utils.dart';

/// Shows the settings screen as an adaptive modal dialog.
void showSettingsModal(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  showAdaptiveModal(
    context: context,
    title: l10n.settings,
    child: const SettingsScreen(),
  );
}

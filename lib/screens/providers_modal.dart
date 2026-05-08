import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/test_screen.dart';
import 'modal_utils.dart';

/// Shows the provider testing screen as an adaptive modal dialog.
void showProvidersModal(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  showAdaptiveModal(
    context: context,
    title: l10n.navProviders,
    child: const TestScreen(),
  );
}

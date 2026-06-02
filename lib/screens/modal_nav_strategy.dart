import 'package:flutter/material.dart';

import '../core/app_logo.dart';
import '../core/registry.dart';
import '../l10n/app_localizations.dart';
import 'modal_utils.dart';
import 'shell_strategy.dart';

/// Modal-first navigation strategy — implements ShellStrategy.
///
/// UploadScreen is always visible. History, Providers, and Settings
/// open as responsive modal dialogs. Selected when shellType setting
/// is 'modals'.
class ModalNavStrategy extends StatelessWidget {
  const ModalNavStrategy({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModalDashboard();
  }
}

class _ModalDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _AppLogo48(),
            const SizedBox(width: 8),
            Text(l10n.appTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            tooltip: l10n.navImageEditor,
            onPressed: () => _showScreen(context, AppScreen.imageEditor),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.history,
            onPressed: () => _showScreen(context, AppScreen.history),
          ),
          IconButton(
            icon: const Icon(Icons.dns),
            tooltip: l10n.navProviders,
            onPressed: () => _showScreen(context, AppScreen.providers),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settings,
            onPressed: () => _showScreen(context, AppScreen.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: devProviders ? 20 : 0),
              child: const _ScreenLookup(screen: AppScreen.upload),
            ),
            if (devProviders)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.orange.shade700,
                  padding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  child: Text(
                    l10n.devBuild,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Helper that looks up the real screen widget from ScreenRegistry.
class _ScreenLookup extends StatelessWidget {
  final AppScreen screen;
  const _ScreenLookup({required this.screen});

  @override
  Widget build(BuildContext context) {
    return ScreenRegistry.build(screen);
  }
}

void _showScreen(BuildContext context, AppScreen screen) {
  final l10n = AppLocalizations.of(context);
  final title = switch (screen) {
    AppScreen.imageEditor => l10n.navImageEditor,
    AppScreen.history => l10n.history,
    AppScreen.providers => l10n.navProviders,
    AppScreen.settings => l10n.settings,
    AppScreen.upload =>
      throw StateError('Upload screen is never shown as modal'),
  };
  showAdaptiveModal(
    context: context,
    title: title,
    child: ScreenRegistry.build(screen),
  );
}

class _AppLogo48 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppLogo(size: 72);
  }
}

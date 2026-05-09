import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_logo.dart';
import '../core/version.dart';
import '../l10n/app_localizations.dart';
import 'shell_strategy.dart';

/// Tab-based navigation strategy — implements ShellStrategy.
///
/// Preserves the existing bottom/left/right navigation logic.
/// Selected when shellType setting is 'tabs' (the default).
class TabNavStrategy extends ConsumerStatefulWidget {
  const TabNavStrategy({super.key});

  @override
  ConsumerState<TabNavStrategy> createState() => _TabNavStrategyState();
}

class _TabNavStrategyState extends ConsumerState<TabNavStrategy> {
  /// The default screen shown by this strategy.
  AppScreen get initialScreen => AppScreen.upload;

  /// Not used — navigation is driven by setState.
  void navigate(BuildContext context, AppScreen screen) {}

  _NavTab _selected = _NavTab.upload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    if (isDesktop) {
      return _buildLeftRailScaffold(context, l10n);
    }

    // Mobile/tablet: bottom nav on narrow screens, left rail on wide
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _buildBottomNavScaffold(context, l10n);
        } else {
          return _buildLeftRailScaffold(context, l10n);
        }
      },
    );
  }

  Widget _buildBottomNavScaffold(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AppLogo(size: 64),
            const SizedBox(width: 8),
            Text(l10n.appTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(_selected.label(l10n),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: BottomNavigationBar(
          currentIndex: _selected.index,
          onTap: (i) => setState(() => _selected = _NavTab.values[i]),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          items: _NavTab.values
              .map((t) => BottomNavigationBarItem(
                    icon: Icon(t.icon),
                    label: t.label(l10n),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildLeftRailScaffold(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 80,
            child: Column(
              children: [
                const SizedBox(height: 16),
                AppLogo(size: 96),
                const SizedBox(height: 4),
                Text(l10n.appTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Expanded(
                  child: NavigationRail(
                    selectedIndex: _selected.index,
                    onDestinationSelected: (i) =>
                        setState(() => _selected = _NavTab.values[i]),
                    labelType: NavigationRailLabelType.all,
                    selectedIconTheme: IconThemeData(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    unselectedIconTheme: IconThemeData(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    selectedLabelTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                    unselectedLabelTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    destinations: _NavTab.values
                        .map((t) => NavigationRailDestination(
                              icon: Icon(t.icon),
                              label: Text(t.label(l10n)),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color:
                      Theme.of(context).dividerColor.withValues(alpha: 0.3))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(
              l10n.appTitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              'v$appVersion',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return switch (_selected) {
      _NavTab.upload => const _ScreenLookup(screen: AppScreen.upload),
      _NavTab.history => const _ScreenLookup(screen: AppScreen.history),
      _NavTab.providers => const _ScreenLookup(screen: AppScreen.providers),
      _NavTab.settings => const _ScreenLookup(screen: AppScreen.settings),
    };
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

enum _NavTab { upload, history, providers, settings }

extension on _NavTab {
  String label(AppLocalizations l10n) => switch (this) {
        _NavTab.upload => l10n.upload,
        _NavTab.history => l10n.history,
        _NavTab.providers => l10n.navProviders,
        _NavTab.settings => l10n.settings,
      };

  IconData get icon => switch (this) {
        _NavTab.upload => Icons.cloud_upload,
        _NavTab.history => Icons.history,
        _NavTab.providers => Icons.dns,
        _NavTab.settings => Icons.settings,
      };
}

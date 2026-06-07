import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_logo.dart';
import '../core/registry.dart';
import '../core/settings_service.dart' show navigationLayoutProvider;
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
      final navLayout =
          ref.watch(navigationLayoutProvider).asData?.value ?? 'left';
      return switch (navLayout) {
        'bottom' => _buildBottomNavScaffold(context, l10n),
        'right' => _buildRightRailScaffold(context, l10n),
        _ => _buildLeftRailScaffold(context, l10n),
      };
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
            AppLogo(size: 72),
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
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: BottomNavigationBar(
          currentIndex: _selected.index,
          onTap: (i) => _onTapTab(i, l10n),
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
    final railWidth = _calculateRailWidth(l10n);
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(width: railWidth, child: _buildRailContent(context, l10n)),
            const VerticalDivider(width: 1),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, l10n),
    );
  }

  Widget _buildRightRailScaffold(BuildContext context, AppLocalizations l10n) {
    final railWidth = _calculateRailWidth(l10n);
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Expanded(child: _buildBody()),
            const VerticalDivider(width: 1),
            SizedBox(width: railWidth, child: _buildRailContent(context, l10n)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, l10n),
    );
  }

  Widget _buildRailContent(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        const SizedBox(height: 16),
        AppLogo(size: 112),
        const SizedBox(height: 4),
        Text(l10n.appTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        Expanded(
          child: NavigationRail(
            selectedIndex: _selected.index,
            onDestinationSelected: (i) => _onTapTab(i, l10n),
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
    );
  }

  Widget _buildBottomBar(BuildContext context, AppLocalizations l10n) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3))),
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
            l10n.versionPrefix(appVersion),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  double _calculateRailWidth(AppLocalizations l10n) {
    double maxWidth = 72; // NavigationRail default min width
    const style = TextStyle(fontSize: 12);
    for (final tab in _NavTab.values) {
      final tp = TextPainter(
        text: TextSpan(text: tab.label(l10n), style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      maxWidth =
          math.max(maxWidth, tp.width + 32); // label + horizontal padding
    }
    return maxWidth;
  }

  void _onTapTab(int i, AppLocalizations l10n) {
    final tab = _NavTab.values[i];
    if (tab == _selected) return;
    final state = ref.read(canSwitchTabProvider);
    if (!state.canSwitch) {
      _showUnsavedWarning(context, l10n, tab, state.onSave);
      return;
    }
    setState(() => _selected = tab);
  }

  void _showUnsavedWarning(BuildContext context, AppLocalizations l10n,
      _NavTab tab, Future<void> Function()? onSave) async {
    final action = await showDialog<_DiscardTabAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.unsavedChangesTitle),
        content: Text(l10n.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _DiscardTabAction.cancel),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _DiscardTabAction.discard),
            child: Text(l10n.discard),
          ),
          if (onSave != null)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, _DiscardTabAction.save),
              child: Text(l10n.save),
            ),
        ],
      ),
    );
    if (action == null || action == _DiscardTabAction.cancel) return;
    if (action == _DiscardTabAction.save && onSave != null) {
      await onSave();
    }
    ref.read(canSwitchTabProvider.notifier).allow();
    setState(() => _selected = tab);
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);
    final screen = switch (_selected) {
      _NavTab.upload => const _ScreenLookup(screen: AppScreen.upload),
      _NavTab.imageEditor => const _ScreenLookup(screen: AppScreen.imageEditor),
      _NavTab.history => const _ScreenLookup(screen: AppScreen.history),
      _NavTab.providers => const _ScreenLookup(screen: AppScreen.providers),
      _NavTab.settings => const _ScreenLookup(screen: AppScreen.settings),
    };

    if (!devProviders) return screen;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: screen,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: Colors.orange.shade700,
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
            child: Text(
              l10n.devBuild,
              style: TextStyle(
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

enum _DiscardTabAction { save, discard, cancel }

enum _NavTab { upload, imageEditor, history, providers, settings }

extension on _NavTab {
  String label(AppLocalizations l10n) => switch (this) {
        _NavTab.upload => l10n.upload,
        _NavTab.imageEditor => l10n.navImageEditor,
        _NavTab.history => l10n.history,
        _NavTab.providers => l10n.navProviders,
        _NavTab.settings => l10n.settings,
      };

  IconData get icon => switch (this) {
        _NavTab.upload => Icons.cloud_upload,
        _NavTab.imageEditor => Icons.palette,
        _NavTab.history => Icons.history,
        _NavTab.providers => Icons.dns,
        _NavTab.settings => Icons.settings,
      };
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'screens/upload_screen.dart';

void main() {
  runApp(const ProviderScope(child: UppidiApp()));
}

class UppidiApp extends StatelessWidget {
  const UppidiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'uppidi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AdaptiveHomePage(),
    );
  }
}

enum _NavTab { upload, history, settings }

extension on _NavTab {
  String label(AppLocalizations l10n) => switch (this) {
        _NavTab.upload => l10n.upload,
        _NavTab.history => l10n.history,
        _NavTab.settings => l10n.settings,
      };

  IconData get icon => switch (this) {
        _NavTab.upload => Icons.cloud_upload,
        _NavTab.history => Icons.history,
        _NavTab.settings => Icons.settings,
      };
}

class AdaptiveHomePage extends StatefulWidget {
  const AdaptiveHomePage({super.key});

  @override
  State<AdaptiveHomePage> createState() => _AdaptiveHomePageState();
}

class _AdaptiveHomePageState extends State<AdaptiveHomePage> {
  _NavTab _selected = _NavTab.upload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Scaffold(
            appBar: AppBar(title: Text(_selected.label(l10n))),
            body: _buildBody(),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selected.index,
              onTap: (i) => setState(() => _selected = _NavTab.values[i]),
              items: _NavTab.values
                  .map((t) => BottomNavigationBarItem(
                        icon: Icon(t.icon),
                        label: t.label(l10n),
                      ))
                  .toList(),
            ),
          );
        }
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _selected.index,
                onDestinationSelected: (i) =>
                    setState(() => _selected = _NavTab.values[i]),
                labelType: NavigationRailLabelType.all,
                destinations: _NavTab.values
                    .map((t) => NavigationRailDestination(
                          icon: Icon(t.icon),
                          label: Text(t.label(l10n)),
                        ))
                    .toList(),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: _buildBody()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return switch (_selected) {
      _NavTab.upload => const UploadScreen(),
      _NavTab.history => const _PlaceholderScreen(tab: _NavTab.history),
      _NavTab.settings => const _PlaceholderScreen(tab: _NavTab.settings),
    };
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final _NavTab tab;
  const _PlaceholderScreen({required this.tab});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tab.icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            tab.label(l10n),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.grey.shade400,
                ),
          ),
        ],
      ),
    );
  }
}

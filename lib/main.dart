import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/app_logo.dart';
import 'core/models/upload_record.dart';
import 'core/settings_service.dart';
import 'core/share_handler.dart';
import 'core/theme_provider.dart';
import 'core/version.dart';
import 'l10n/app_localizations.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/test_screen.dart';
import 'screens/upload_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UploadRecordAdapter());
  runApp(const ProviderScope(child: UppidiApp()));
}

class UppidiApp extends ConsumerStatefulWidget {
  const UppidiApp({super.key});

  @override
  ConsumerState<UppidiApp> createState() => _UppidiAppState();
}

class _UppidiAppState extends ConsumerState<UppidiApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Platform.isAndroid || Platform.isIOS) {
        ShareHandler.init(context, ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = ref.watch(localeCodeProvider).asData?.value;
    final seed = ref.watch(seedColorProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Uppidi Upload',
      locale: localeCode != null ? Locale(localeCode) : null,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AdaptiveHomePage(),
    );
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

class AdaptiveHomePage extends ConsumerStatefulWidget {
  const AdaptiveHomePage({super.key});

  @override
  ConsumerState<AdaptiveHomePage> createState() => _AdaptiveHomePageState();
}

class _AdaptiveHomePageState extends ConsumerState<AdaptiveHomePage> {
  _NavTab _selected = _NavTab.upload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final navLayoutAsync = ref.watch(navigationLayoutProvider);
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    if (isDesktop) {
      final layout = navLayoutAsync.asData?.value ?? 'bottom';
      return switch (layout) {
        'left' => _buildLeftRailScaffold(context, l10n),
        'right' => _buildRightRailScaffold(context, l10n),
        _ => _buildBottomNavScaffold(context, l10n),
      };
    }

    // Non-desktop: adaptive based on width
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
            AppLogo(size: 48),
            const SizedBox(width: 8),
            Text(l10n.appTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(_selected.label(l10n), style: TextStyle(
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
                AppLogo(size: 72),
                const SizedBox(height: 4),
                Text(l10n.appTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.3))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(l10n.appTitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text('v$appVersion',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightRailScaffold(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(child: _buildBody()),
          const VerticalDivider(width: 1),
          SizedBox(
            width: 80,
            child: Column(
              children: [
                const SizedBox(height: 16),
                AppLogo(size: 72),
                const SizedBox(height: 4),
                Text(l10n.appTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
        ],
      ),
      bottomNavigationBar: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.3))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(l10n.appTitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text('v$appVersion',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return switch (_selected) {
      _NavTab.upload => const UploadScreen(),
      _NavTab.history => const HistoryScreen(),
      _NavTab.providers => const TestScreen(),
      _NavTab.settings => const SettingsScreen(),
    };
  }
}

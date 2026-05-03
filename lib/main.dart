import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/models/upload_record.dart';
import 'core/settings_service.dart';
import 'core/share_handler.dart';
import 'l10n/app_localizations.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
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
      ShareHandler.init(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = ref.watch(localeCodeProvider).asData?.value;
    return MaterialApp(
      title: 'uppidi',
      locale: localeCode != null ? Locale(localeCode) : null,
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
            appBar: AppBar(
              title: Row(
                children: [
                  Image.asset('assets/logo.png', width: 28, height: 28),
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
              SizedBox(
                width: 80,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Image.asset('assets/logo.png', width: 40, height: 40),
                    const SizedBox(height: 4),
                    Text(l10n.appTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: NavigationRail(
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
                    ),
                  ],
                ),
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
      _NavTab.history => const HistoryScreen(),
      _NavTab.settings => const SettingsScreen(),
    };
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/app_logo.dart';
import 'core/models/upload_record.dart';
import 'core/settings_service.dart';
import 'core/share_handler.dart';
import 'core/theme_provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/history_screen.dart';
import 'screens/modal_nav_strategy.dart';
import 'screens/settings_screen.dart';
import 'screens/shell_strategy.dart';
import 'screens/tab_nav_strategy.dart';
import 'screens/test_screen.dart';
import 'screens/upload_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UploadRecordAdapter());
  _registerScreens();
  runApp(const ProviderScope(child: UppidiApp()));
}

/// Registers all app screens in ScreenRegistry.
///
/// This is the single point of coupling between the screen layer and the
/// navigation shell. ShellStrategy implementations are decoupled from
/// concrete screen widgets — they ask ScreenRegistry for the right widget.
void _registerScreens() {
  ScreenRegistry.register(AppScreen.upload, () => const UploadScreen());
  ScreenRegistry.register(AppScreen.history, () => const HistoryScreen());
  ScreenRegistry.register(AppScreen.providers, () => const TestScreen());
  ScreenRegistry.register(AppScreen.settings, () => const SettingsScreen());
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
    final shellType = ref.watch(shellTypeProvider).asData?.value ?? 'tabs';

    return MaterialApp(
      title: 'Uppidi Upload',
      locale: localeCode != null ? Locale(localeCode) : null,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: switch (shellType) {
        'modals' => const ModalNavStrategy(),
        _ => const TabNavStrategy(),
      },
    );
  }
}

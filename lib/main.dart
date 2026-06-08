import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_skill/flutter_skill.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/logging/log.dart';
import 'core/logging/observers.dart';
import 'core/models/upload_record.dart';
import 'core/registry.dart';
import 'core/settings_service.dart';
import 'core/share_handler.dart';
import 'core/theme_provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/history_screen.dart';
import 'screens/image_editor_screen.dart';
import 'screens/modal_nav_strategy.dart';
import 'screens/settings_screen.dart';
import 'screens/shell_strategy.dart';
import 'screens/tab_nav_strategy.dart';
import 'screens/test_screen.dart';
import 'screens/upload_screen.dart';

/// A custom delegate that loads AppLocalizations for the user's chosen
/// language regardless of what locale Flutter resolves for Material.
/// This lets us use locales like 'tlh' or 'eo' that Flutter's Material
/// library doesn't support — our strings work, Material falls back to English.
class _UserLangDelegate extends LocalizationsDelegate<AppLocalizations> {
  final String languageCode;

  const _UserLangDelegate(this.languageCode);

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      AppLocalizations.delegate.load(Locale(languageCode));

  @override
  bool shouldReload(_UserLangDelegate old) => old.languageCode != languageCode;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) FlutterSkillBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UploadRecordAdapter());
  await Hive.openBox<String>('settings');
  final savedLogging =
      Hive.box<String>('settings').get(SettingsService.debugLoggingKey);
  Log.enableFileLogging(savedLogging == 'true');
  _registerScreens();
  try {
    await ProviderRegistry.init();
  } on PlatformException catch (e) {
    stderr.writeln('FATAL: ${e.code}: ${e.message}');
    if (e.code == 'KeyringLocked') {
      stderr.writeln(
          'The desktop secret service keyring is locked or inaccessible.\n'
          'Ensure GNOME Keyring / KDE Wallet is unlocked.\n'
          'For Flatpak: the sandbox needs D-Bus access — '
          'restart your session or run:\n'
          '  flatpak override --user com.uppidi.uppidi '
          '--talk-name=org.freedesktop.secrets');
    }
    exit(1);
  }
  runZonedGuarded(
    () => runApp(
      ProviderScope(
        observers: [TracingObserver()],
        child: const UppidiApp(),
      ),
    ),
    (e, s) => Log('App').error('Uncaught: $e', error: e, stackTrace: s),
  );
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
  ScreenRegistry.register(
    AppScreen.imageEditor,
    () => const ImageEditorScreen(),
  );
}

class UppidiApp extends ConsumerStatefulWidget {
  const UppidiApp({super.key});

  @override
  ConsumerState<UppidiApp> createState() => _UppidiAppState();
}

class _UppidiAppState extends ConsumerState<UppidiApp> {
  late final RouteTracer _routeTracer = RouteTracer();

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
    final localeCode = ref.watch(localeCodeProvider).asData?.value ?? 'en';
    final seed = ref.watch(seedColorProvider);
    final themeMode = ref.watch(themeModeProvider);
    final shellType = ref.watch(shellTypeProvider).asData?.value ?? 'tabs';

    // Our custom delegate always loads the user's language for app strings.
    // Material delegates resolve independently (English for unsupported
    // locales like tlh/eo, the user's locale for en/it/tr).
    final userDelegate = _UserLangDelegate(localeCode);

    return MaterialApp(
      title: 'Uppidi Upload',
      debugShowCheckedModeBanner: false,
      locale: localeCode == 'tlh' || localeCode == 'eo'
          ? const Locale('en')
          : Locale(localeCode),
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
      localizationsDelegates: [
        userDelegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('it'),
        Locale('tr'),
      ],
      navigatorObservers: [_routeTracer],
      home: switch (shellType) {
        'modals' => const ModalNavStrategy(),
        _ => const TabNavStrategy(),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_service.dart';

/// Theme mode: persists system/light/dark preference.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final mode = await ref.read(settingsServiceProvider).getThemeMode();
    state = mode;
  }

  Future<void> setMode(ThemeMode mode) async {
    final key = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await ref.read(settingsServiceProvider).set(SettingsService.themeModeKey, key);
    state = mode;
  }
}

/// Seed color for dynamic theming. Persisted as hex.
final seedColorProvider =
    NotifierProvider<SeedColorNotifier, Color>(SeedColorNotifier.new);

class SeedColorNotifier extends Notifier<Color> {
  @override
  Color build() {
    _load();
    return Colors.deepPurple;
  }

  Future<void> _load() async {
    final color = await ref.read(settingsServiceProvider).getSeedColor();
    state = color;
  }

  Future<void> setColor(Color color) async {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    await ref.read(settingsServiceProvider).set(SettingsService.seedColorKey, hex);
    state = color;
  }
}

/// Custom logo path (null = use asset default).
final logoPathProvider =
    NotifierProvider<LogoPathNotifier, String?>(LogoPathNotifier.new);

class LogoPathNotifier extends Notifier<String?> {
  @override
  String? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final path = await ref.read(settingsServiceProvider).getLogoPath();
    state = path;
  }

  Future<void> setPath(String? path) async {
    if (path == null) {
      await ref.read(settingsServiceProvider).remove(SettingsService.logoPathKey);
    } else {
      await ref.read(settingsServiceProvider).set(SettingsService.logoPathKey, path);
    }
    state = path;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'history_screen.dart';
import 'image_editor_screen.dart';
import 'settings_screen.dart';
import 'test_screen.dart';
import 'upload_screen.dart';

/// Provider for screens to block tab switching (e.g. unsaved edits).
final canSwitchTabProvider =
    NotifierProvider<CanSwitchTabNotifier, CanSwitchTabState>(
  CanSwitchTabNotifier.new,
);

class CanSwitchTabState {
  final bool canSwitch;
  final Future<void> Function()? onSave;
  const CanSwitchTabState({this.canSwitch = true, this.onSave});
}

class CanSwitchTabNotifier extends Notifier<CanSwitchTabState> {
  @override
  CanSwitchTabState build() => const CanSwitchTabState();

  void block({Future<void> Function()? onSave}) =>
      state = CanSwitchTabState(canSwitch: false, onSave: onSave);
  void allow() => state = const CanSwitchTabState();
}

/// Screens available in the app navigation.
///
/// Each concrete ShellStrategy interprets these screens according to its
/// own paradigm (tabs switch to the screen, modals open it as a dialog,
/// etc.). Screens are never aware of which strategy is active.
enum AppScreen { upload, imageEditor, history, providers, settings }

/// Signature for building a screen widget.
typedef ScreenBuilder = Widget Function();

/// Registry of all app screens. Each entry maps a screen identifier to
/// its widget constructor.
class ScreenRegistry {
  ScreenRegistry._();

  static final Map<AppScreen, ScreenBuilder> screens = {};

  /// Registers [screen] with its [builder]. Call once per screen at startup.
  static void register(AppScreen screen, ScreenBuilder builder) {
    screens[screen] = builder;
  }

  /// Builds the widget for [screen].
  ///
  /// If [screen] is not registered (e.g., running outside of main()), falls
  /// back to returning the real widget directly. This allows tests that
  /// instantiate widgets without going through main() to still render.
  static Widget build(AppScreen screen) {
    final builder = screens[screen];
    if (builder != null) return builder();
    return _fallback(screen);
  }

  static Widget _fallback(AppScreen screen) {
    return switch (screen) {
      AppScreen.upload => const UploadScreen(),
      AppScreen.imageEditor => const ImageEditorScreen(),
      AppScreen.history => const HistoryScreen(),
      AppScreen.providers => const TestScreen(),
      AppScreen.settings => const SettingsScreen(),
    };
  }
}

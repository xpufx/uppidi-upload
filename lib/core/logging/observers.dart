import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'log.dart';

/// Traces all Riverpod provider state changes. One line captures every
/// state machine transition, settings change, and config update.
base class TracingObserver extends ProviderObserver {
  static final _log = Log('Tracing');

  /// Provider name substrings to skip entirely (noisy tickers).
  static const _skip = ['AgeTick', 'VersionCheck'];

  /// Provider name substrings whose values should be redacted.
  static const _secret = ['provider_config', 'ProviderConfig'];

  /// Only log providers whose name starts with these prefixes.
  static const _only = ['Upload', 'Settings', 'ProviderConfig', 'Export'];

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    final name =
        context.provider.name ?? context.provider.runtimeType.toString();
    for (final s in _skip) {
      if (name.contains(s)) return;
    }
    if (!_only.any((p) => name.startsWith(p))) return;
    for (final s in _secret) {
      if (name.contains(s)) {
        _log.debug('$name: <redacted>');
        return;
      }
    }
    _log.debug('$name: $newValue');
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    final name =
        context.provider.name ?? context.provider.runtimeType.toString();
    _log.error('$name failed: $error', error: error, stackTrace: stackTrace);
  }
}

/// Traces all Navigator route changes (screen enter/leave).
class RouteTracer extends NavigatorObserver {
  static final _log = Log('Route');

  @override
  void didPush(Route route, Route? previousRoute) {
    _log.info('→ ${route.settings.name ?? route.runtimeType}');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _log.info('← ${route.settings.name ?? route.runtimeType}');
  }
}

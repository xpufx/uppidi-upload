import 'package:flutter_test/flutter_test.dart';
import 'package:uppidi_upload/core/health/provider_health.dart';

void main() {
  group('parseHealthManifest — flat (legacy)', () {
    test('parses flat provider map', () {
      final parsed = parseHealthManifest({
        'httpbin': {
          'disabled': false,
          'since': null,
          'reason': null,
          'failureCount': 0,
        },
        'catbox': {
          'disabled': true,
          'since': '2026-01-01T00:00:00Z',
          'reason': 'connectionTimedOut',
        },
      });

      expect(parsed.keys, containsAll(['httpbin', 'catbox']));
      expect(parsed['httpbin']!.disabled, isFalse);
      expect(parsed['catbox']!.disabled, isTrue);
      expect(parsed['catbox']!.reason, 'connectionTimedOut');
      expect(parsed['catbox']!.failureCount, 0);
    });
  });

  group('parseHealthManifest — versioned', () {
    test('unwraps providers object and reads metadata', () {
      final parsed = parseHealthManifest({
        'version': 1,
        'updated': '2026-02-01T12:00:00Z',
        'providers': {
          'frisk': {
            'disabled': true,
            'since': '2026-02-01T00:00:00Z',
            'reason': 'genericError',
            'failureCount': 3,
            'checked': '2026-02-01T12:00:00Z',
          },
        },
      });

      expect(parsed.length, 1);
      final frisk = parsed['frisk']!;
      expect(frisk.disabled, isTrue);
      expect(frisk.failureCount, 3);
      expect(frisk.checked, '2026-02-01T12:00:00Z');
    });

    test('ignores non-map metadata values', () {
      final parsed = parseHealthManifest({
        'version': 1,
        'updated': 'not-a-provider',
        'providers': {'catbox': {'disabled': false}},
      });
      expect(parsed.keys, ['catbox']);
    });
  });

  group('parseHealthManifest — robustness', () {
    test('returns empty for non-map input', () {
      expect(parseHealthManifest('nonsense'), isEmpty);
      expect(parseHealthManifest(null), isEmpty);
      expect(parseHealthManifest([1, 2, 3]), isEmpty);
    });
  });

  group('applyProbeResult — two-strike transition', () {
    final t1 = DateTime.utc(2026, 3, 1, 10);
    final t2 = DateTime.utc(2026, 3, 1, 16);
    final t3 = DateTime.utc(2026, 3, 2, 10);

    test('first failure increments but does not disable', () {
      final info = applyProbeResult(null, success: false, now: t1, reason: 'x');
      expect(info.disabled, isFalse);
      expect(info.failureCount, 1);
      expect(info.since, isNull);
      expect(info.checked, t1.toIso8601String());
    });

    test('second failure disables and stamps since', () {
      final first = applyProbeResult(null, success: false, now: t1);
      final second =
          applyProbeResult(first, success: false, now: t2, reason: 'x');
      expect(second.disabled, isTrue);
      expect(second.failureCount, 2);
      expect(second.since, t2.toIso8601String());
      expect(second.reason, 'x');
    });

    test('further failures preserve the original since', () {
      final first = applyProbeResult(null, success: false, now: t1);
      final second = applyProbeResult(first, success: false, now: t2);
      final third = applyProbeResult(second, success: false, now: t3);
      expect(third.disabled, isTrue);
      expect(third.failureCount, 3);
      expect(third.since, t2.toIso8601String());
    });

    test('success resets counter and re-enables', () {
      final disabled = ProviderHealthInfo(
        disabled: true,
        failureCount: 4,
        since: t1.toIso8601String(),
        reason: 'x',
      );
      final recovered = applyProbeResult(disabled, success: true, now: t2);
      expect(recovered.disabled, isFalse);
      expect(recovered.failureCount, 0);
      expect(recovered.since, isNull);
      expect(recovered.reason, isNull);
      expect(recovered.checked, t2.toIso8601String());
    });
  });

  group('buildHealthManifest', () {
    test('emits versioned shape with providers', () {
      final manifest = buildHealthManifest({
        'httpbin': const ProviderHealthInfo(disabled: false, failureCount: 0),
        'catbox': const ProviderHealthInfo(
          disabled: true,
          failureCount: 2,
          reason: 'connectionTimedOut',
        ),
      }, DateTime.utc(2026, 3, 1));

      expect(manifest['version'], 1);
      expect(manifest['updated'], '2026-03-01T00:00:00.000Z');
      final providers = manifest['providers'] as Map;
      expect(providers['httpbin']['disabled'], isFalse);
      expect(providers['catbox']['failureCount'], 2);
    });

    test('round-trips through the parser', () {
      final manifest = buildHealthManifest({
        'frisk': const ProviderHealthInfo(disabled: true, failureCount: 2),
      }, DateTime.utc(2026, 3, 1));
      final parsed = parseHealthManifest(manifest);
      expect(parsed['frisk']!.disabled, isTrue);
      expect(parsed['frisk']!.failureCount, 2);
    });
  });
}

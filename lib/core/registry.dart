import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'interfaces/uploader.dart';
import 'models/provider_instance.dart';
import 'models/provider_metadata.dart';
import 'provider_config_sheet.dart';
import 'settings_service.dart';
import '../providers/catbox_provider.dart';
import '../providers/fileditch_provider.dart';
import '../providers/freeimage_provider.dart';
import '../providers/frisk_provider.dart';
import '../providers/httpbin_provider.dart';
import '../providers/litterbox_provider.dart';
import '../providers/tempsh_provider.dart';
import '../providers/telegram_provider.dart';
import '../providers/tmpfilelink_provider.dart';
import '../providers/uguu_provider.dart';
import '../providers/zulip_provider.dart';

const bool devProviders = bool.fromEnvironment('DEV_PROVIDERS');

final enabledProvidersProvider = Provider<List<BaseUploader>>((ref) {
  final disabled = ref.watch(disabledProviderIdsProvider).asData?.value ?? {};
  return ProviderRegistry.all
      .where((p) => !disabled.contains(p.providerId))
      .toList();
});

/// Base provider types — the "blueprints" that get wrapped with instances.
final List<BaseUploader> _baseTypes = [
  HttpBinProvider(),
  FileDitchProvider(),
  FriskProvider(),
  UguuProvider(name: 'uguu.se', url: 'https://uguu.se'),
  TmpFileLinkProvider(),
  CatboxProvider(),
  FreeImageHostProvider(
    name: 'freeimage.host',
    url: 'https://freeimage.host',
  ),
  TempShProvider(),
  LitterboxProvider(),
  TelegramProvider(),
  ZulipProvider(),
  if (devProviders)
    UguuProvider(
      name: 'Uguu (milan)',
      url: 'https://uguu.milan.xpufx.com',
      endpoint: '/upload.php',
      metadata: const ProviderMetadata(
        maxFileSizeBytes: 128 * 1024 * 1024,
        supportsDirectLink: true,
        expiryInfo: '8 hours',
      ),
    ),
];

class ProviderRegistry {
  /// All available provider instances. Populated by [init] at startup.
  /// Before init, returns the base provider types (for test compatibility).
  static List<BaseUploader> all = List.of(_baseTypes);

  /// Loads instances from secure storage and builds the provider list.
  /// Auth providers (requiresAuth capability) only appear when they have
  /// at least one configured instance.  Non-auth providers always appear.
  static Future<void> init() async {
    final result = <BaseUploader>[];
    for (final base in _baseTypes) {
      final instances = await loadProviderInstances(base.providerId);
      if (instances.isEmpty) {
        // Only add bare base type if it doesn't need auth config
        if (!base.metadata.capabilities
            .contains(ProviderCapability.requiresAuth)) {
          result.add(base);
        }
      } else {
        for (final inst in instances) {
          result.add(ProviderInstance(base, inst.id, inst.name));
        }
      }
    }
    all = result;
  }

  /// Re-runs [init] and notifies watchers so the provider dropdown etc.
  /// update immediately without restart.
  static Future<void> refresh(WidgetRef ref) async {
    await init();
    ref.invalidate(enabledProvidersProvider);
  }

  /// Returns the base provider type for a given (possibly instance-scoped)
  /// providerId.  E.g. `telegram__work` → the TelegramProvider blueprint.
  static BaseUploader? baseFor(String providerId) {
    final baseId = providerId.split('__').first;
    for (final b in _baseTypes) {
      if (b.providerId == baseId) return b;
    }
    return null;
  }

  /// True when [provider] is a base type (not an instance wrapper).
  static bool isBaseType(BaseUploader provider) =>
      provider is! ProviderInstance;

  /// Returns all base provider types that can be added as instances in the
  /// "My Providers" dialog. Only providers with a non-null
  /// [BaseUploader.instanceDescription] appear here.
  static List<BaseUploader> get instanceTypes =>
      _baseTypes.where((b) => b.instanceDescription != null).toList();
}

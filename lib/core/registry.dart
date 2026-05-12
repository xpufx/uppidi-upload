import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'interfaces/uploader.dart';
import 'settings_service.dart';
import '../providers/catbox_provider.dart';
import '../providers/fileditch_provider.dart';
import '../providers/freeimage_provider.dart';
import '../providers/frisk_provider.dart';
import '../providers/httpbin_provider.dart';
import '../providers/litterbox_provider.dart';
import '../providers/tempsh_provider.dart';
import '../providers/tmpfilelink_provider.dart';
import '../providers/uguu_provider.dart';

final enabledProvidersProvider = Provider<List<BaseUploader>>((ref) {
  final disabled = ref.watch(disabledProviderIdsProvider).asData?.value ?? {};
  return ProviderRegistry.all
      .where((p) => !disabled.contains(p.providerId))
      .toList();
});

class ProviderRegistry {
  static final List<BaseUploader> all = [
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
  ];
}

import 'interfaces/uploader.dart';
import '../providers/catbox_provider.dart';
import '../providers/freeimage_provider.dart';
import '../providers/httpbin_provider.dart';
import '../providers/tempsh_provider.dart';
import '../providers/tmpfilelink_provider.dart';
import '../providers/uguu_provider.dart';
import 'models/provider_metadata.dart';

class ProviderRegistry {
  static final List<BaseUploader> all = [
    HttpBinProvider(),
    UguuProvider(name: 'uguu.se', url: 'https://uguu.se'),
    UguuProvider(name: 'safe.uguu.se', url: 'https://safe.uguu.se',
      metadata: const ProviderMetadata(maxFileSizeBytes: 128 * 1024 * 1024)),
    TmpFileLinkProvider(),
    CatboxProvider(),
    FreeImageHostProvider(
      name: 'freeimage.host',
      url: 'https://freeimage.host',
      apiKey: '6d207e02198a847aa98d0a2a901485a5',
    ),
    TempShProvider(),
  ];
}

import 'interfaces/uploader.dart';
import '../providers/catbox_provider.dart';
import '../providers/httpbin_provider.dart';

class ProviderRegistry {
  static final List<BaseUploader> all = [
    HttpBinProvider(),
    // CatboxProvider(),
    // ImmichProvider(),
    // Future providers go here – one line each.
  ];
}

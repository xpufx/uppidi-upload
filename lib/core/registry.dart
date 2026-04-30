import 'interfaces/uploader.dart';
import '../providers/httpbin_provider.dart';
import '../providers/tmpfilelink_provider.dart';

class ProviderRegistry {
  static final List<BaseUploader> all = [
    HttpBinProvider(),
    TmpFileLinkProvider(),
    // CatboxProvider(),
    // ImmichProvider(),
    // Future providers go here – one line each.
  ];
}

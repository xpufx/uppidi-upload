import 'interfaces/uploader.dart';
import '../providers/catbox_provider.dart';
import '../providers/httpbin_provider.dart';
import '../providers/tmpfilelink_provider.dart';
import '../providers/uguu_provider.dart';

class ProviderRegistry {
  static final List<BaseUploader> all = [
    HttpBinProvider(),
    UguuProvider(),
    TmpFileLinkProvider(),
    CatboxProvider(),
  ];
}

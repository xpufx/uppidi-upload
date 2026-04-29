import 'interfaces/uploader.dart';
import '../providers/catbox_provider.dart';

class ProviderRegistry {
  static final List<BaseUploader> all = [
    CatboxProvider(),
    // ImmichProvider(),
    // Future providers go here – one line each.
  ];
}

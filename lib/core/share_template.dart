class ShareTemplate {
  static const appName = 'Uppidi Upload';
  
  /// Supported template variables shown to users
  static const Map<String, String> variables = {
    '%url': 'The uploaded file URL',
    '%provider': 'The hosting provider name (e.g., Catbox.moe)',
    '%date': 'Current date/time',
    '%filename': 'Original filename',
    '%appname': 'Uppidi Upload',
  };

  /// Replace template variables in message with actual values
  static String expand(String template, {String? url, String? provider, DateTime? date, String? filename}) {
    return template
        .replaceAll('%url', url ?? '')
        .replaceAll('%provider', provider ?? '')
        .replaceAll('%date', date?.toLocal().toString().substring(0, 19) ?? '')
        .replaceAll('%filename', filename ?? '')
        .replaceAll('%appname', appName);
  }

  /// Example templates for the info popup
  static const List<String> examples = [
    'Shared via %appname: %url',
    '%filename uploaded to %provider: %url',
    'Check this out — %url',
  ];
}
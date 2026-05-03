import 'package:hive/hive.dart';

import 'upload_result.dart';

class UploadRecord {
  final String fileName;
  final String? url;
  final String providerId;
  final String providerName;
  final bool success;
  final String? errorMessage;
  final int? statusCode;
  final DateTime completedAt;

  UploadRecord({
    required this.fileName,
    this.url,
    required this.providerId,
    required this.providerName,
    required this.success,
    this.errorMessage,
    this.statusCode,
    required this.completedAt,
  });

  factory UploadRecord.fromResult(UploadResult result, String providerId, String providerName) {
    return UploadRecord(
      fileName: _extractFileName(result),
      url: result.url,
      providerId: providerId,
      providerName: providerName,
      success: result.success,
      errorMessage: result.errorMessage,
      statusCode: result.statusCode,
      completedAt: result.completedAt,
    );
  }

  static String _extractFileName(UploadResult result) {
    if (result.url != null) {
      final segments = Uri.tryParse(result.url!)?.pathSegments;
      if (segments != null && segments.isNotEmpty) {
        return segments.last;
      }
    }
    return 'unknown';
  }
}

class UploadRecordAdapter extends TypeAdapter<UploadRecord> {
  @override
  final int typeId = 0;

  @override
  UploadRecord read(BinaryReader reader) {
    return UploadRecord(
      fileName: reader.readString(),
      url: reader.readBool() ? reader.readString() : null,
      providerId: reader.readString(),
      providerName: reader.readString(),
      success: reader.readBool(),
      errorMessage: reader.readBool() ? reader.readString() : null,
      statusCode: reader.readBool() ? reader.readInt() : null,
      completedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, UploadRecord obj) {
    writer.writeString(obj.fileName);
    writer.writeBool(obj.url != null);
    if (obj.url != null) writer.writeString(obj.url!);
    writer.writeString(obj.providerId);
    writer.writeString(obj.providerName);
    writer.writeBool(obj.success);
    writer.writeBool(obj.errorMessage != null);
    if (obj.errorMessage != null) writer.writeString(obj.errorMessage!);
    writer.writeBool(obj.statusCode != null);
    if (obj.statusCode != null) writer.writeInt(obj.statusCode!);
    writer.writeInt(obj.completedAt.millisecondsSinceEpoch);
  }
}

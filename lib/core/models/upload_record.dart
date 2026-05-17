import 'dart:typed_data';

import 'package:hive/hive.dart';

class UploadRecord {
  final String fileName;
  final String? url;
  final String providerId;
  final String providerName;
  final bool success;
  final String? errorMessage;
  final int? statusCode;
  final DateTime completedAt;
  final Uint8List? thumbnailBytes;
  final String? expiry;

  UploadRecord({
    required this.fileName,
    this.url,
    required this.providerId,
    required this.providerName,
    required this.success,
    this.errorMessage,
    this.statusCode,
    required this.completedAt,
    this.thumbnailBytes,
    this.expiry,
  });
}

class UploadRecordAdapter extends TypeAdapter<UploadRecord> {
  @override
  final int typeId = 0;

  @override
  UploadRecord read(BinaryReader reader) {
    var record = UploadRecord(
      fileName: reader.readString(),
      url: reader.readBool() ? reader.readString() : null,
      providerId: reader.readString(),
      providerName: reader.readString(),
      success: reader.readBool(),
      errorMessage: reader.readBool() ? reader.readString() : null,
      statusCode: reader.readBool() ? reader.readInt() : null,
      completedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );

    // Backward compat: old records won't have thumbnailBytes
    try {
      final thumbList = reader.readByteList();
      if (thumbList.isNotEmpty) {
        record = UploadRecord(
          fileName: record.fileName,
          url: record.url,
          providerId: record.providerId,
          providerName: record.providerName,
          success: record.success,
          errorMessage: record.errorMessage,
          statusCode: record.statusCode,
          completedAt: record.completedAt,
          thumbnailBytes: Uint8List.fromList(thumbList),
        );
      }
    } catch (_) {
      // Old record without thumbnail data — return as-is
    }
    // Backward compat: old records won't have expiry
    try {
      if (reader.readBool()) {
        record = UploadRecord(
          fileName: record.fileName,
          url: record.url,
          providerId: record.providerId,
          providerName: record.providerName,
          success: record.success,
          errorMessage: record.errorMessage,
          statusCode: record.statusCode,
          completedAt: record.completedAt,
          thumbnailBytes: record.thumbnailBytes,
          expiry: reader.readString(),
        );
      }
    } catch (_) {
      // Old record without expiry — return as-is
    }
    return record;
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
    // thumbnailBytes appended here for backward compat
    writer.writeByteList(obj.thumbnailBytes ?? []);
    // expiry appended last for backward compat
    writer.writeBool(obj.expiry != null);
    if (obj.expiry != null) writer.writeString(obj.expiry!);
  }
}

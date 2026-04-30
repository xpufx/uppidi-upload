class FileUploadRequest {
  final String fileName;
  final String? mimeType;
  final int sizeInBytes;
  final Stream<List<int>> dataStream;

  const FileUploadRequest({
    required this.fileName,
    this.mimeType,
    required this.sizeInBytes,
    required this.dataStream,
  });
}

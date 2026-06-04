import 'package:pro_image_editor/pro_image_editor.dart';

class ImageFormatInfo {
  final OutputFormat outputFormat;
  final String mimeType;
  final String extension;

  const ImageFormatInfo({
    required this.outputFormat,
    required this.mimeType,
    required this.extension,
  });
}

ImageFormatInfo imageFormatFromFileName(String fileName) {
  final ext = fileName.split('.').last.toLowerCase();
  switch (ext) {
    case 'png':
      return const ImageFormatInfo(
        outputFormat: OutputFormat.png,
        mimeType: 'image/png',
        extension: 'png',
      );
    case 'gif':
      return const ImageFormatInfo(
        outputFormat: OutputFormat.png,
        mimeType: 'image/png',
        extension: 'png',
      );
    case 'webp':
      return const ImageFormatInfo(
        outputFormat: OutputFormat.png,
        mimeType: 'image/png',
        extension: 'png',
      );
    case 'bmp':
      return const ImageFormatInfo(
        outputFormat: OutputFormat.png,
        mimeType: 'image/png',
        extension: 'png',
      );
    case 'tiff':
    case 'tif':
      return const ImageFormatInfo(
        outputFormat: OutputFormat.tiff,
        mimeType: 'image/tiff',
        extension: 'tiff',
      );
    case 'ico':
      return const ImageFormatInfo(
        outputFormat: OutputFormat.png,
        mimeType: 'image/png',
        extension: 'png',
      );
    case 'jpg':
    case 'jpeg':
    default:
      return const ImageFormatInfo(
        outputFormat: OutputFormat.jpg,
        mimeType: 'image/jpeg',
        extension: 'jpg',
      );
  }
}

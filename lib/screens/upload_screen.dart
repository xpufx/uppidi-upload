import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../core/interfaces/uploader.dart';
import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';
import '../core/registry.dart';
import '../providers/upload_provider.dart';

class UploadScreen extends ConsumerWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(uploadProvider);
    final notifier = ref.read(uploadProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: uploadState.isUploading ? null : notifier.pickAndUpload,
            child: Text(uploadState.isUploading ? 'Uploading...' : 'Pick & Upload'),
          ),
          if (uploadState.isUploading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: uploadState.progress),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: notifier.cancelUpload,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cancel'),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: uploadState.results.length,
              itemBuilder: (context, index) {
                final r = uploadState.results[index];
                return ListTile(
                  leading: Icon(
                    r.success ? Icons.check_circle : Icons.error,
                    color: r.success ? Colors.green : Colors.red,
                  ),
                  title: Text(r.success ? 'Success' : 'Failed'),
                  subtitle: Text(r.success
                      ? '${r.url ?? ''} (Status: ${r.statusCode})'
                      : '${r.errorMessage ?? 'Unknown error'} (Status: ${r.statusCode})'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadScreenState extends State<UploadScreen> {
  final List<UploadResult> _results = [];
  double _progress = 0.0;
  bool _uploading = false;
  CancelToken? _cancelToken;

  Future<void> _pickAndUpload() async {
    final pickResult = await FilePicker.platform.pickFiles();
    if (pickResult == null || pickResult.files.isEmpty) return;

    final file = pickResult.files.first;
    if (file.path == null) return;

    final provider = ProviderRegistry.all.first;
    final fileStream = File(file.path!).openRead();
    final size = await File(file.path!).length();

    final request = FileUploadRequest(
      fileName: file.name,
      mimeType: file.extension != null ? 'application/${file.extension}' : null,
      sizeInBytes: size,
      dataStream: fileStream,
    );

    setState(() {
      _uploading = true;
      _progress = 0.0;
    });

    _cancelToken = CancelToken();

    final result = await provider.upload(
      request,
      onProgress: (sent, total) {
        setState(() {
          _progress = sent / total;
        });
      },
      cancelToken: _cancelToken,
    );

    setState(() {
      _uploading = false;
      _results.insert(0, result);
    });
  }

  void _cancelUpload() {
    _cancelToken?.cancel('User cancelled');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _uploading ? null : _pickAndUpload,
            child: Text(_uploading ? 'Uploading...' : 'Pick & Upload'),
          ),
          if (_uploading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _cancelUpload,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cancel'),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final r = _results[index];
                return ListTile(
                  leading: Icon(
                    r.success ? Icons.check_circle : Icons.error,
                    color: r.success ? Colors.green : Colors.red,
                  ),
                  title: Text(r.success ? 'Success' : 'Failed'),
                  subtitle: Text(r.success ? r.url ?? '' : '${r.errorMessage ?? 'Unknown error'} (Status: ${r.statusCode})'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

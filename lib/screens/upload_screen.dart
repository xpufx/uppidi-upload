import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          DropdownButton<int>(
            value: uploadState.selectedProviderIndex,
            isExpanded: true,
            onChanged: uploadState.isUploading
                ? null
                : (index) {
                    if (index != null) {
                      notifier.setProvider(index);
                    }
                  },
            items: ProviderRegistry.all.asMap().entries.map((entry) {
              final provider = entry.value;
              return DropdownMenuItem(
                value: entry.key,
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(provider.providerName),
                    const SizedBox(width: 4),
                    Text(
                      '(${provider.providerId})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
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
          if (uploadState.lastError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.shade100,
              child: Text(
                'Error: ${uploadState.lastError}',
                style: TextStyle(color: Colors.red.shade800),
              ),
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
                  subtitle: r.success && r.url != null
                      ? Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                r.url!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: r.url!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('URL copied to clipboard')),
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: r.url!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('URL copied to clipboard')),
                                );
                              },
                              tooltip: 'Copy URL',
                            ),
                          ],
                        )
                      : Text(r.success
                          ? 'Status: ${r.statusCode}'
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
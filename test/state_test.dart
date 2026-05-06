import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uppidi_upload/core/models/upload_result.dart';
import 'package:uppidi_upload/providers/upload_provider.dart';

void main() {
  group('UploadState sealed classes', () {
    test('UploadIdle has no progress or errors', () {
      const state = UploadIdle();
      expect(state.results, isEmpty);
      expect(state.selectedProviderIndex, 0);

      final typed = state as UploadState;
      expect(typed is UploadIdle, isTrue);
      expect(typed is UploadInProgress, isFalse);
      expect(typed is UploadCompleted, isFalse);
    });

    test('UploadInProgress carries progress and cancelToken', () {
      final token = CancelToken();
      final state = UploadInProgress(progress: 0.5, cancelToken: token);

      expect(state.progress, 0.5);
      expect(state.cancelToken, same(token));

      final typed = state as UploadState;
      expect(typed is UploadInProgress, isTrue);
    });

    test('UploadInProgress copyWithProgress preserves fields', () {
      final token = CancelToken();
      final state = UploadInProgress(
        progress: 0.3,
        cancelToken: token,
        results: [UploadResult(success: true, url: 'https://x.com')],
        selectedProviderIndex: 1,
        providers: [],
      );

      final updated = state.copyWithProgress(0.7, state.sentBytes, state.totalBytes, state.speedLabel);
      expect(updated.progress, 0.7);
      expect(updated.cancelToken, same(token));
      expect(updated.results.length, 1);
      expect(updated.selectedProviderIndex, 1);
    });

    test('UploadCompleted carries lastResult and optional errorMessage', () {
      final success = UploadCompleted(
        lastResult: UploadResult(success: true, url: 'https://x.com'),
      );
      expect(success.isSuccess, isTrue);
      expect(success.errorMessage, isNull);

      final failure = UploadCompleted(
        lastResult: UploadResult(success: false),
        errorMessage: 'genericError',
      );
      expect(failure.isSuccess, isFalse);
      expect(failure.errorMessage, 'genericError');
    });

    test('switch exhaustiveness is enforced by compiler', () {
      // This verifies all sealed subtypes are handled.
      // If a new subclass is added, this would fail to compile.
      String describe(UploadState state) => switch (state) {
            UploadIdle() => 'idle',
            UploadFileSelected() => 'file_selected',
            UploadInProgress() => 'in_progress',
            UploadCompleted() => 'completed',
          };

      expect(describe(const UploadIdle()), 'idle');
      expect(
        describe(UploadFileSelected(fileName: 'a', fileSizeBytes: 1)),
        'file_selected',
      );
      expect(
        describe(UploadInProgress(progress: 0, cancelToken: CancelToken())),
        'in_progress',
      );
      expect(
        describe(UploadCompleted(
          lastResult: UploadResult(success: true),
        )),
        'completed',
      );
    });
  });
}

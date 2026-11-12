// lib/view_models/document_view_model.dart
import 'package:flutter/material.dart';
import '../core/utils/user_helper.dart';
import '../data/repositories/doc_repository.dart';

class DocumentViewModel extends ChangeNotifier {
  final DocRepository _repo = DocRepository();

  bool isUploading = false;
  String statusText = '';
  String? error;
  int? importedCount;

  int? _count(dynamic result) {
    if (result is Map && result['total_transactions'] is num) {
      return (result['total_transactions'] as num).toInt();
    }
    return null;
  }

  /// Statement file eka upload karanawa. Success nam true.
  Future<bool> upload(String filePath) async {
    isUploading = true;
    error = null;
    importedCount = null;
    statusText = 'Uploading statement...';
    notifyListeners();

    final userId = currentUserId();
    try {
      final res = await _repo.uploadStatement(filePath, userId);

      if (res['done'] == true) {
        importedCount = _count(res['data']);
      } else {
        // Image / scanned PDF: background eke process wenawa, poll karanna oni
        final jobId = res['jobId'].toString();
        statusText = 'Reading your statement (scanned files take longer)...';
        notifyListeners();

        var finished = false;
        for (var i = 0; i < 100 && !finished; i++) {
          await Future.delayed(const Duration(seconds: 3));
          final job = await _repo.getUploadStatus(jobId, userId);
          final status = job['status'];

          if (status == 'completed') {
            importedCount = _count(job['result']);
            finished = true;
          } else if (status == 'failed') {
            throw ApiException(
              job['error']?.toString() ?? 'Statement processing failed.',
            );
          }
        }
        if (!finished) {
          throw ApiException('Processing took too long. Please try again.');
        }
      }

      statusText = 'Done';
      isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      statusText = '';
      isUploading = false;
      notifyListeners();
      return false;
    }
  }
}

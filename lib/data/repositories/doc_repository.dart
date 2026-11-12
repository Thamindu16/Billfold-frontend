// lib/data/repositories/doc_repository.dart
//
// Statement upload + dashboard data (summary, categories, transactions,
// budget, savings, overspending, anomalies) - okkoma methanin.
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class DocRepository {
  static const Duration _timeout = Duration(seconds: 30);

  Uri _uri(String path, String userId, [Map<String, String>? extra]) {
    return Uri.parse('${ApiConstants.baseUrl}$path').replace(
      queryParameters: {'user_id': userId, ...?extra},
    );
  }

  /// GET karala {"status","message","data"} ekka 'data' eka return karanawa.
  Future<dynamic> _get(
    String path,
    String userId, [
    Map<String, String>? extra,
  ]) async {
    try {
      final res = await http.get(_uri(path, userId, extra)).timeout(_timeout);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return body['data'];
      throw ApiException(_errorText(body, res.statusCode));
    } on ApiException {
      rethrow;
    } on Exception {
      throw ApiException(
        'Could not connect to the server. Is the backend running?',
      );
    }
  }

  String _errorText(dynamic body, int code) {
    if (body is Map) {
      final msg = body['error'] ?? body['message'] ?? body['detail'];
      if (msg != null) return msg.toString();
    }
    return 'Server error ($code)';
  }

  // ---------- Dashboard data ----------

  /// total_income, total_expenses, net_savings, savings_rate_percentage, currency ...
  Future<Map<String, dynamic>> getSummary(String userId) async {
    final data = await _get('/analytics/summary', userId);
    return Map<String, dynamic>.from(data);
  }

  /// [{category, total_amount, transaction_count, average_amount, percentage_share, currency}]
  Future<List<Map<String, dynamic>>> getCategories(String userId) async {
    final data = await _get('/analytics/categories', userId) as List;
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// [{id, date, description, amount, type, category, balance, currency}]
  Future<List<Map<String, dynamic>>> getTransactions(
    String userId, {
    int limit = 50,
  }) async {
    final data = await _get('/transactions', userId, {'limit': '$limit'});
    final list = data['transactions'] as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// {total_suggested_budget, category_budgets: [...]}
  Future<Map<String, dynamic>> getBudget(String userId) async {
    final data = await _get('/recommendations/budget', userId);
    return Map<String, dynamic>.from(data);
  }

  /// {savings_summary, discretionary_cuts, recurring_subscriptions, ...}
  Future<Map<String, dynamic>> getSavings(String userId) async {
    final data = await _get('/recommendations/savings', userId);
    return Map<String, dynamic>.from(data);
  }

  /// {overall_status, categories: [{status: ok|warning|over, ...}], summary}
  Future<Map<String, dynamic>> getOverspending(String userId) async {
    final data = await _get('/detection/overspending', userId);
    return Map<String, dynamic>.from(data);
  }

  /// {anomalies: [{description, amount, reason, ...}], total_anomalies}
  Future<Map<String, dynamic>> getAnomalies(String userId) async {
    final data = await _get('/detection/anomalies', userId);
    return Map<String, dynamic>.from(data);
  }

  // ---------- Upload ----------

  /// Return:
  ///   {'done': true,  'data': {...extraction result...}}   (CSV/Excel/normal PDF)
  ///   {'done': false, 'jobId': '...'}                      (image / scanned PDF)
  Future<Map<String, dynamic>> uploadStatement(
    String filePath,
    String userId,
  ) async {
    try {
      final req = http.MultipartRequest(
        'POST',
        _uri('/upload-statement', userId),
      );
      req.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamed = await req.send().timeout(const Duration(minutes: 2));
      final res = await http.Response.fromStream(streamed);
      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return {'done': true, 'data': body['data']};
      }
      if (res.statusCode == 202) {
        return {'done': false, 'jobId': body['data']['job_id']};
      }
      throw ApiException(_errorText(body, res.statusCode));
    } on ApiException {
      rethrow;
    } on Exception {
      throw ApiException(
        'Upload failed. Check the backend and your internet connection.',
      );
    }
  }

  /// {job_id, status: queued|processing|completed|failed, result?, error?}
  Future<Map<String, dynamic>> getUploadStatus(
    String jobId,
    String userId,
  ) async {
    final data = await _get('/upload-status/$jobId', userId);
    return Map<String, dynamic>.from(data);
  }
}

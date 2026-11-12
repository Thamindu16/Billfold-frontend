// lib/data/repositories/chat_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

class ChatRepository {
  /// POST /chat  ->  {"response": "...", "source": "..."}
  Future<String> sendMessage(String message, String userId) async {
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message, 'user_id': userId}),
          )
          .timeout(const Duration(seconds: 60));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return body['response'].toString();
      }
      final msg = (body is Map ? (body['message'] ?? body['detail']) : null);
      throw Exception(msg ?? 'Chat failed (${res.statusCode})');
    } on Exception catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

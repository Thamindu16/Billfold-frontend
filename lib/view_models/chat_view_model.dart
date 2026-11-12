// lib/view_models/chat_view_model.dart
import 'package:flutter/material.dart';
import '../core/utils/user_helper.dart';
import '../data/repositories/chat_repository.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, this.isUser);
}

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repo = ChatRepository();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  Future<void> send(String text) async {
    final msg = text.trim();
    if (msg.isEmpty || _isLoading) return;

    _messages.add(ChatMessage(msg, true));
    _isLoading = true;
    notifyListeners();

    try {
      final reply = await _repo.sendMessage(msg, currentUserId());
      _messages.add(ChatMessage(reply, false));
    } catch (e) {
      _messages.add(ChatMessage('Sorry, something went wrong: $e', false));
    }

    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _messages.clear();
    notifyListeners();
  }
}

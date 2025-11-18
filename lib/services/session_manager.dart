import 'dart:html' as html;
import 'chatbot_api.dart';
import '../models/message.dart';

class SessionManager {
  static const String _storageKey = 'chatbot_session_id';
  final ChatbotApi api;

  SessionManager(this.api);

  String? getSessionId() {
    try {
      final id = html.window.localStorage[_storageKey];
      if (id != null && id.isNotEmpty) {
        print('Stored session found: $id');
      } else {
        print('No stored session');
      }
      return id;
    } catch (_) {
      return null;
    }
  }

  void saveSessionId(String sessionId) {
    try {
      html.window.localStorage[_storageKey] = sessionId;
      print('Session saved to localStorage: $sessionId');
    } catch (_) {}
  }

  void clearSession() {
    try {
      html.window.localStorage.remove(_storageKey);
      print('Session cleared from localStorage');
    } catch (_) {}
  }

  Future<List<Message>> restoreMessages(String sessionId) async {
    final history = await api.getHistory(sessionId);
    return history.map((h) => Message.fromJson(h)).toList();
  }
}
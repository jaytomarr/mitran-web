import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotApi {
  final String baseUrl;

  ChatbotApi({
    this.baseUrl = 'https://mitran-chatbot.onrender.com',
  });

  Future<String> createSession() async {
    final uri = Uri.parse('$baseUrl/v1/sessions');
    try {
      final response = await http.post(uri);
      if (response.statusCode != 200) {
        throw Exception('Failed to create session: ${response.statusCode}');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final id = data['session_id'];
      if (id is String && id.isNotEmpty) return id;
      throw Exception('Invalid session id');
    } catch (e) {
      throw Exception('Create session error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHistory(String sessionId) async {
    final uri = Uri.parse('$baseUrl/v1/chat/history?session_id=${Uri.encodeComponent(sessionId)}');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 404) {
        throw Exception('Session not found');
      }
      if (response.statusCode != 200) {
        throw Exception('Failed to load history: ${response.statusCode}');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final messages = data['messages'];
      if (messages is List) {
        return messages.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Get history error: $e');
    }
  }

  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String> sendMessage({
    required String sessionId,
    required String text,
  }) async {
    final postUri = Uri.parse('$baseUrl/v1/chat/send');
    try {
      final postResp = await http.post(
        postUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'session_id': sessionId, 'text': text}),
      );
      if (postResp.statusCode == 404) {
        throw Exception('Session not found');
      }
      if (postResp.statusCode == 429) {
        throw Exception('Rate limit exceeded');
      }
      if (postResp.statusCode != 200) {
        throw Exception('Failed to send: ${postResp.statusCode}');
      }
      final data = jsonDecode(postResp.body) as Map<String, dynamic>;
      final t = _extractReply(data);
      return t;
    } catch (e) {
      throw Exception('Send message error: $e');
    }
  }

  String _extractReply(Map<String, dynamic> data) {
    if (data.containsKey('delta') && data['delta'] is String) {
      return data['delta'] as String;
    }
    if (data.containsKey('text') && data['text'] is String) {
      return data['text'] as String;
    }
    if (data.containsKey('content') && data['content'] is String) {
      return data['content'] as String;
    }
    final m = data['message'];
    if (m is String) return m;
    return '';
  }
}
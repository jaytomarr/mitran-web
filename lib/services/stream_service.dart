import 'dart:async';
import 'dart:html' as html;
import 'dart:convert';

class StreamService {
  Stream<String> streamMessage({
    required String baseUrl,
    required String sessionId,
    required String text,
  }) {
    final url = '$baseUrl/v1/chat/stream?session_id=${Uri.encodeComponent(sessionId)}&text=${Uri.encodeComponent(text)}';

    final controller = StreamController<String>();
    html.EventSource? eventSource;

    try {
      eventSource = html.EventSource(url);

      eventSource.onMessage.listen((html.MessageEvent event) {
        final raw = event.data as String?;
        if (raw == null || raw.isEmpty) return;
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            if (decoded.containsKey('delta') && decoded['delta'] is String) {
              final payload = jsonEncode({'type': 'delta', 'text': decoded['delta']});
              controller.add(payload);
              return;
            }
            if (decoded.containsKey('text') && decoded['text'] is String) {
              final payload = jsonEncode({'type': 'full', 'text': decoded['text']});
              controller.add(payload);
              return;
            }
            if (decoded.containsKey('content') && decoded['content'] is String) {
              final payload = jsonEncode({'type': 'full', 'text': decoded['content']});
              controller.add(payload);
              return;
            }
          }
        } catch (_) {
          if (raw.isNotEmpty) {
            final payload = jsonEncode({'type': 'delta', 'text': raw});
            controller.add(payload);
            return;
          }
        }
      });

      eventSource.onError.listen((event) {
        controller.addError(Exception('Stream error'));
        eventSource?.close();
      });
    } catch (e) {
      controller.addError(e);
    }

    controller.onCancel = () {
      eventSource?.close();
    };

    return controller.stream;
  }
}
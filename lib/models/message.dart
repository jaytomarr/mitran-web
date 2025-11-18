class Message {
  final String text;
  final String role;
  final DateTime timestamp;
  final bool isStreaming;

  const Message({
    required this.text,
    required this.role,
    required this.timestamp,
    this.isStreaming = false,
  });

  Message copyWith({
    String? text,
    String? role,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return Message(
      text: text ?? this.text,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      text: json['text'] as String? ?? '',
      role: json['role'] as String? ?? 'assistant',
      timestamp: DateTime.now(),
    );
  }
}
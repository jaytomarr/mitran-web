import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final bool enabled;
  final bool isStreaming;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.enabled,
    required this.isStreaming,
  });

  void _handleSend() {
    final text = controller.text.trim();
    if (text.isNotEmpty && enabled) {
      onSend(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                maxLines: null,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: isStreaming ? 'Waiting for response...' : 'Type your message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: enabled ? (_) => _handleSend() : null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: enabled ? _handleSend : null,
              icon: Icon(Icons.send, color: enabled ? const Color(0xFF007AFF) : Colors.grey),
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }
}
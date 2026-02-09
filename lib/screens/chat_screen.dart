import 'package:flutter/material.dart';
import 'dart:async';
import '../models/message.dart';
import '../services/chatbot_api.dart';
import '../services/session_manager.dart';
import '../services/stream_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/design_system.dart';

class ChatScreen extends StatefulWidget {
  final bool embedded;
  const ChatScreen({super.key, this.embedded = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatbotApi _chatbotApi;
  late final SessionManager _sessionManager;
  late final StreamService _streamService;

  String? _sessionId;
  final List<Message> _messages = [];
  bool _isLoading = true;
  bool _isStreaming = false;
  String _error = '';
  String _streamBuffer = '';
  bool _receivedChunk = false;
  String? _pendingText;

  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  StreamSubscription<String>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _chatbotApi = ChatbotApi();
    _sessionManager = SessionManager(_chatbotApi);
    _streamService = StreamService();
    _initFromLocal();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _initFromLocal() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final storedId = _sessionManager.getSessionId();
    if (storedId == null || storedId.isEmpty) {
      print('Initializing: no session in localStorage');
      setState(() {
        _sessionId = null;
        _messages.clear();
        _isLoading = false;
      });
      return;
    }
    try {
      print('Initializing: restoring session $storedId');
      final msgs = await _sessionManager.restoreMessages(storedId);
      print('Restored messages count: ${msgs.length}');
      setState(() {
        _sessionId = storedId;
        _messages.clear();
        _messages.addAll(msgs);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      print('Restore failed: $e');
      setState(() {
        _sessionId = null;
        _messages.clear();
        _isLoading = false;
        _error = 'Failed to restore session';
      });
    }
  }

  Future<void> _createSession() async {
    setState(() {
      _error = '';
      _isLoading = true;
    });
    final ok = await _chatbotApi.checkHealth();
    if (!ok) {
      print('Health check failed');
      setState(() {
        _isLoading = false;
        _error = 'Service is unavailable';
      });
      return;
    }
    print('Health check OK');
    try {
      final id = await _chatbotApi.createSession();
      print('Created session: $id');
      _sessionManager.saveSessionId(id);
      setState(() {
        _sessionId = id;
        _messages.clear();
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      print('Create session error: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to create session';
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isStreaming || _sessionId == null) return;
    if (_pendingText != null) return;

    final userMessage = Message(text: trimmed, role: 'user', timestamp: DateTime.now());
    setState(() {
      _messages.add(userMessage);
      _isStreaming = true;
      _streamBuffer = '';
      _error = '';
      _pendingText = trimmed;
    });

    _inputController.clear();
    _scrollToBottom();

    final assistantMessage = Message(text: '', role: 'assistant', timestamp: DateTime.now(), isStreaming: true);
    setState(() {
      _messages.add(assistantMessage);
    });
    try {
      final reply = await _chatbotApi.sendMessage(sessionId: _sessionId!, text: trimmed);
      setState(() {
        _isStreaming = false;
        if (_messages.isNotEmpty && _messages.last.isAssistant) {
          _messages[_messages.length - 1] = _messages.last.copyWith(text: reply, isStreaming: false);
        } else {
          _messages.add(Message(text: reply, role: 'assistant', timestamp: DateTime.now()));
        }
        _pendingText = null;
      });
      _scrollToBottom();
    } catch (_) {
      setState(() {
        _isStreaming = false;
        _error = 'No response received';
        if (_messages.isNotEmpty && _messages.last.isStreaming) {
          _messages.removeLast();
        }
        _pendingText = trimmed;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _refreshLastFromHistory() async {
    try {
      if (_sessionId == null) return;
      final history = await _chatbotApi.getHistory(_sessionId!);
      if (history.isNotEmpty) {
        final last = history.last;
        final role = last['role'] as String? ?? '';
        final text = last['text'] as String? ?? '';
        if (role == 'assistant' && text.isNotEmpty) {
          setState(() {
            if (_messages.isNotEmpty && _messages.last.isAssistant) {
              _messages[_messages.length - 1] = _messages.last.copyWith(text: text, isStreaming: false);
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _pollHistoryForAssistant() async {
    if (_sessionId == null) return;
    for (int i = 0; i < 8; i++) {
      try {
        final history = await _chatbotApi.getHistory(_sessionId!);
        if (history.isNotEmpty) {
          final last = history.last;
          final role = last['role'] as String? ?? '';
          final text = last['text'] as String? ?? '';
          if (role == 'assistant' && text.isNotEmpty) {
            setState(() {
              if (_messages.isNotEmpty && _messages.last.isAssistant) {
                _messages[_messages.length - 1] = _messages.last.copyWith(text: text, isStreaming: false);
              } else {
                _messages.add(Message(text: text, role: 'assistant', timestamp: DateTime.now()));
              }
            });
            _scrollToBottom();
            return;
          }
        }
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final header = Column(
      children: [
        if (_error.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_error, style: const TextStyle(color: AppColors.error))),
                if (_pendingText != null)
                  TextButton(
                    onPressed: _resendNonStream, 
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    child: const Text('Resend'),
                  ),
                TextButton(
                  onPressed: _initFromLocal, 
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  child: const Text('New Session'),
                ),
              ],
            ),
          ),
      ],
    );

    final body = Column(
      children: [
        header,
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _sessionId == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: AppGradients.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.white),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Start a conversation',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ask about dog health, behavior, or nutrition',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          GradientButton(
                            text: 'Start Chat',
                            onPressed: _createSession,
                          ),
                        ],
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return MessageBubble(message: _messages[index]);
                        },
                      ),
                    ),
        ),
        if (!_isLoading && _sessionId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ChatInput(
              controller: _inputController,
              onSend: _sendMessage,
              enabled: !_isStreaming,
              isStreaming: _isStreaming,
            ),
          ),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('AI Chatbot'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      body: body,
    );
  }

  Future<void> _resendNonStream() async {
    if (_pendingText == null || _isStreaming || _sessionId == null) return;
    setState(() {
      _isStreaming = true;
      _error = '';
      if (_messages.isNotEmpty && _messages.last.isAssistant) {
        _messages[_messages.length - 1] = _messages.last.copyWith(isStreaming: true);
      } else {
        _messages.add(Message(text: '', role: 'assistant', timestamp: DateTime.now(), isStreaming: true));
      }
    });
    try {
      final reply = await _chatbotApi.sendMessage(sessionId: _sessionId!, text: _pendingText!);
      setState(() {
        _isStreaming = false;
        if (_messages.isNotEmpty && _messages.last.isAssistant) {
          _messages[_messages.length - 1] = _messages.last.copyWith(text: reply, isStreaming: false);
        }
        _pendingText = null;
      });
      _scrollToBottom();
    } catch (_) {
      setState(() {
        _isStreaming = false;
        _error = 'No response received';
        if (_messages.isNotEmpty && _messages.last.isStreaming) {
          _messages.removeLast();
        }
      });
    }
  }
}
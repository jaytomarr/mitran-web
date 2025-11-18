# Product Requirements Document
## AI Chatbot - Flutter Web Application

**Version:** 2.0  
**Date:** November 17, 2025  
**Platform:** Flutter Web with Firebase Integration  
**API Name:** `chatbot_api` (generic for multiple chatbot integrations)

---

## 🤖 FOR AI IDE: IMPLEMENTATION INSTRUCTIONS

This PRD contains **complete, copy-paste ready code** for a Flutter Web chatbot application.

### **CRITICAL INSTRUCTIONS FOR AI:**
1. **Create ALL files exactly as shown** - file paths are clearly marked
2. **Do NOT modify the code** - it is production-tested
3. **Follow the exact folder structure** specified
4. **API base URL** is configurable - can be changed in one place
5. **All code includes error handling** - do not add extra try-catch blocks
6. **Variable naming**: Use `chatbotApi` NOT `mitranApi` throughout
7. **Service naming**: Use `ChatbotApi` class NOT `MitranApi`

### **FILE CREATION ORDER:**
1. Create `pubspec.yaml` first
2. Create models folder and `message.dart`
3. Create services folder: `chatbot_api.dart`, `session_manager.dart`, `stream_service.dart`
4. Create widgets folder: `message_bubble.dart`, `chat_input.dart`
5. Create screens folder: `chat_screen.dart`
6. Create `main.dart`

---

## 1. Executive Summary

A clean, minimalist chat interface for Flutter Web that integrates with AI chatbot APIs. Features real-time streaming responses, persistent sessions via localStorage, and an intuitive conversation experience. Designed to work with multiple chatbot API providers.

---

## 2. Storage Strategy

**DECISION: Use localStorage (NOT Firestore)**

**Why:**
- ✅ Faster (synchronous access)
- ✅ No Firebase costs
- ✅ Simple implementation
- ✅ Perfect for temporary chats
- ✅ Session ID only (~50 bytes)
- ✅ API is source of truth for history

**What's Stored:**
- Session ID only
- Message history fetched from API on restore

---

## 3. Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/
│   └── message.dart                   # Message data model
├── services/
│   ├── chatbot_api.dart              # API service layer (RENAMED)
│   ├── session_manager.dart          # Session lifecycle
│   └── stream_service.dart           # SSE streaming
├── screens/
│   └── chat_screen.dart              # Main chat UI
└── widgets/
    ├── message_bubble.dart           # Message display
    └── chat_input.dart               # Input field
```

---

## 4. Dependencies File

### 📄 FILE: `pubspec.yaml`
```yaml
name: ai_chatbot_app
description: AI Chatbot Flutter Web Application
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
```

---

## 5. Complete Implementation Code

### 📄 FILE: `lib/models/message.dart`
```dart
/// Message model for chat messages
class Message {
  final String text;
  final String role; // 'user' or 'assistant'
  final DateTime timestamp;
  final bool isStreaming;

  const Message({
    required this.text,
    required this.role,
    required this.timestamp,
    this.isStreaming = false,
  });

  /// Create a copy with updated fields
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

  /// Check if message is from user
  bool get isUser => role == 'user';
  
  /// Check if message is from assistant
  bool get isAssistant => role == 'assistant';

  /// Create message from API history response
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      text: json['text'] as String,
      role: json['role'] as String,
      timestamp: DateTime.now(),
    );
  }
}
```

---

### 📄 FILE: `lib/services/chatbot_api.dart`
```dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// API service for chatbot integration
/// Handles session creation, history retrieval, and health checks
class ChatbotApi {
  final String baseUrl;

  ChatbotApi({
    this.baseUrl = 'https://mitran-chatbot.onrender.com',
  });

  /// Create a new chat session
  /// Returns: session_id (String)
  /// Throws: Exception on failure
  Future<String> createSession() async {
    final uri = Uri.parse('$baseUrl/v1/sessions');

    try {
      final response = await http.post(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create session: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['session_id'] as String;
    } catch (e) {
      throw Exception('Create session error: $e');
    }
  }

  /// Get conversation history for a session
  /// Returns: List of messages [{role: String, text: String}]
  /// Throws: Exception on failure or if session not found
  Future<List<Map<String, dynamic>>> getHistory(String sessionId) async {
    final uri = Uri.parse(
      '$baseUrl/v1/chat/history?session_id=${Uri.encodeComponent(sessionId)}',
    );

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 404) {
        throw Exception('Session not found');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load history: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final messages = data['messages'] as List?;

      return messages?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      throw Exception('Get history error: $e');
    }
  }

  /// Check API health status
  /// Returns: true if healthy, false otherwise
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
```

---

### 📄 FILE: `lib/services/session_manager.dart`
```dart
import 'dart:html' as html;
import 'chatbot_api.dart';
import '../models/message.dart';

/// Result object for session initialization
class SessionResult {
  final String sessionId;
  final List<Message> messages;
  final bool isNew;

  SessionResult({
    required this.sessionId,
    required this.messages,
    required this.isNew,
  });
}

/// Manages chat session lifecycle
/// Handles localStorage persistence and session restoration
class SessionManager {
  static const String _storageKey = 'chatbot_session_id';
  final ChatbotApi api;

  SessionManager(this.api);

  /// Get stored session ID from localStorage
  /// Returns: session_id or null if not found
  String? getSessionId() {
    try {
      return html.window.localStorage[_storageKey];
    } catch (e) {
      print('Error reading session from localStorage: $e');
      return null;
    }
  }

  /// Save session ID to localStorage
  void saveSessionId(String sessionId) {
    try {
      html.window.localStorage[_storageKey] = sessionId;
      print('✓ Session saved: $sessionId');
    } catch (e) {
      print('✗ Error saving session: $e');
    }
  }

  /// Clear session from localStorage
  void clearSession() {
    try {
      html.window.localStorage.remove(_storageKey);
      print('✓ Session cleared');
    } catch (e) {
      print('✗ Error clearing session: $e');
    }
  }

  /// Initialize session: restore existing or create new
  /// Returns: SessionResult with session_id, messages, and isNew flag
  /// Throws: Exception if session creation fails
  Future<SessionResult> initSession() async {
    final storedId = getSessionId();

    if (storedId != null && storedId.isNotEmpty) {
      print('→ Found stored session: $storedId');
      return await _restoreSession(storedId);
    } else {
      print('→ No stored session, creating new one');
      return await _createSession();
    }
  }

  /// Restore existing session from API
  /// Falls back to creating new session if restoration fails
  Future<SessionResult> _restoreSession(String sessionId) async {
    try {
      final history = await api.getHistory(sessionId);
      final messages = history.map((h) => Message.fromJson(h)).toList();

      print('✓ Restored ${messages.length} messages');
      return SessionResult(
        sessionId: sessionId,
        messages: messages,
        isNew: false,
      );
    } catch (e) {
      print('✗ Restore failed: $e');
      print('→ Falling back to new session');
      clearSession();
      return await _createSession();
    }
  }

  /// Create new session via API
  /// Saves session ID to localStorage on success
  Future<SessionResult> _createSession() async {
    try {
      final sessionId = await api.createSession();
      saveSessionId(sessionId);

      print('✓ New session created: $sessionId');
      return SessionResult(
        sessionId: sessionId,
        messages: [],
        isNew: true,
      );
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }
}
```

---

### 📄 FILE: `lib/services/stream_service.dart`
```dart
import 'dart:async';
import 'dart:html' as html;

/// Service for handling Server-Sent Events (SSE) streaming
class StreamService {
  /// Stream messages from chatbot API using SSE
  /// 
  /// Parameters:
  ///   - baseUrl: API base URL
  ///   - sessionId: Current session ID
  ///   - text: User message text
  /// 
  /// Returns: Stream of text chunks
  Stream<String> streamMessage({
    required String baseUrl,
    required String sessionId,
    required String text,
  }) {
    final url = '$baseUrl/v1/chat/stream?'
        'session_id=${Uri.encodeComponent(sessionId)}&'
        'text=${Uri.encodeComponent(text)}';

    final controller = StreamController<String>();
    html.EventSource? eventSource;

    try {
      eventSource = html.EventSource(url);

      // Handle incoming messages
      eventSource.onMessage.listen((html.MessageEvent event) {
        final data = event.data as String?;
        if (data != null && data.isNotEmpty) {
          controller.add(data);
        }
      });

      // Handle errors
      eventSource.onError.listen((event) {
        controller.addError(Exception('Stream connection error'));
        eventSource?.close();
      });
    } catch (e) {
      controller.addError(e);
    }

    // Cleanup on stream cancel
    controller.onCancel = () {
      eventSource?.close();
    };

    return controller.stream;
  }
}
```

---

### 📄 FILE: `lib/widgets/message_bubble.dart`
```dart
import 'package:flutter/material.dart';
import '../models/message.dart';

/// Widget for displaying individual chat messages
class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assistant avatar (left side)
          if (message.isAssistant) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: const Icon(
                Icons.smart_toy,
                size: 18,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF007AFF)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  // Streaming indicator
                  if (message.isStreaming)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            message.isUser ? Colors.white : Colors.blue,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // User avatar (right side)
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

---

### 📄 FILE: `lib/widgets/chat_input.dart`
```dart
import 'package:flutter/material.dart';

/// Widget for chat message input field
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
            // Text input field
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                maxLines: null,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: isStreaming
                      ? 'Waiting for response...'
                      : 'Type your message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: enabled ? (_) => _handleSend() : null,
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            IconButton(
              onPressed: enabled ? _handleSend : null,
              icon: Icon(
                Icons.send,
                color: enabled ? const Color(0xFF007AFF) : Colors.grey,
              ),
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 📄 FILE: `lib/screens/chat_screen.dart`
```dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/message.dart';
import '../services/chatbot_api.dart';
import '../services/session_manager.dart';
import '../services/stream_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';

/// Main chat screen widget
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Services
  late final ChatbotApi _chatbotApi;
  late final SessionManager _sessionManager;
  late final StreamService _streamService;

  // State variables
  String? _sessionId;
  final List<Message> _messages = [];
  bool _isLoading = true;
  bool _isStreaming = false;
  String _error = '';

  // Controllers
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  StreamSubscription<String>? _streamSubscription;
  String _streamBuffer = '';

  @override
  void initState() {
    super.initState();
    _chatbotApi = ChatbotApi();
    _sessionManager = SessionManager(_chatbotApi);
    _streamService = StreamService();
    _initSession();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  /// Initialize chat session
  Future<void> _initSession() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final result = await _sessionManager.initSession();

      setState(() {
        _sessionId = result.sessionId;
        _messages.clear();
        _messages.addAll(result.messages);
        _isLoading = false;
      });

      if (result.isNew) {
        _addWelcomeMessage();
      }

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to initialize chat: $e';
      });
    }
  }

  /// Add welcome message for new sessions
  void _addWelcomeMessage() {
    setState(() {
      _messages.add(Message(
        text: 'Hello! How can I help you today?',
        role: 'assistant',
        timestamp: DateTime.now(),
      ));
    });
  }

  /// Send message and start streaming response
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _sessionId == null || _isStreaming) return;

    // Add user message
    final userMessage = Message(
      text: text.trim(),
      role: 'user',
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isStreaming = true;
      _streamBuffer = '';
      _error = '';
    });

    _inputController.clear();
    _scrollToBottom();

    // Add streaming placeholder
    final assistantMessage = Message(
      text: '',
      role: 'assistant',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    setState(() {
      _messages.add(assistantMessage);
    });

    try {
      // Start streaming
      _streamSubscription = _streamService
          .streamMessage(
        baseUrl: _chatbotApi.baseUrl,
        sessionId: _sessionId!,
        text: text.trim(),
      )
          .listen(
        (chunk) {
          // Update message with new chunk
          setState(() {
            _streamBuffer += chunk;
            _messages[_messages.length - 1] = _messages.last.copyWith(
              text: _streamBuffer,
            );
          });
          _scrollToBottom();
        },
        onError: (error) {
          setState(() {
            _isStreaming = false;
            _error = 'Stream error: $error';
            if (_messages.last.isStreaming) {
              _messages.removeLast();
            }
          });
        },
        onDone: () {
          // Finalize message
          setState(() {
            _isStreaming = false;
            if (_messages.last.isAssistant) {
              _messages[_messages.length - 1] = _messages.last.copyWith(
                isStreaming: false,
              );
            }
          });
        },
      );
    } catch (e) {
      setState(() {
        _isStreaming = false;
        _error = 'Failed to send message: $e';
        if (_messages.last.isStreaming) {
          _messages.removeLast();
        }
      });
    }
  }

  /// Scroll to bottom of message list
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

  /// Reset chat and start new session
  Future<void> _resetChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Chat'),
        content: const Text('Start a new conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('New Chat'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _sessionManager.clearSession();
      setState(() {
        _messages.clear();
        _sessionId = null;
      });
      await _initSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('AI Chatbot'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_sessionId != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetChat,
              tooltip: 'New Chat',
            ),
        ],
      ),
      body: Column(
        children: [
          // Error banner
          if (_error.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: _initSession,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Start a conversation',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return MessageBubble(message: _messages[index]);
                        },
                      ),
          ),

          // Input field
          ChatInput(
            controller: _inputController,
            onSend: _sendMessage,
            enabled: !_isLoading && !_isStreaming,
            isStreaming: _isStreaming,
          ),
        ],
      ),
    );
  }
}
```

---

### 📄 FILE: `lib/main.dart`
```dart
import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const AIChatbotApp());
}

/// Main application widget
class AIChatbotApp extends StatelessWidget {
  const AIChatbotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chatbot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}
```

---

## 6. API Configuration

### Changing the API Base URL

**Location:** `lib/services/chatbot_api.dart`

```dart
// Current (Mitran API)
ChatbotApi({
  this.baseUrl = 'https://mitran-chatbot.onrender.com',
});

// Change to your API
ChatbotApi({
  this.baseUrl = 'https://your-api-url.com',
});
```

### API Endpoints Required

Your chatbot API must support these endpoints:

1. **POST** `/v1/sessions`
   - Response: `{"session_id": "uuid"}`

2. **GET** `/v1/chat/history?session_id=<id>`
   - Response: `{"messages": [{"role": "user|assistant", "text": "..."}]}`

3. **GET** `/v1/chat/stream?session_id=<id>&text=<message>`
   - Response: SSE stream with `data: <chunk>` format

4. **GET** `/health`
   - Response: `{"status": "ok"}`

---

## 7. Setup Instructions

```bash
# Step 1: Create Flutter project
flutter create ai_chatbot_app
cd ai_chatbot_app

# Step 2: Add http dependency
flutter pub add http

# Step 3: Create folder structure
mkdir -p lib/models lib/services lib/screens lib/widgets

# Step 4: Copy all files from this PRD into respective folders
# - Copy pubspec.yaml content
# - Copy all lib/* files

# Step 5: Get dependencies
flutter pub get

# Step 6: Run on web
flutter run -d chrome

# Step 7: Build for production
flutter build web --release
```

---

## 8. How It Works

### Session Flow
```
1. App loads
   ↓
2. SessionManager checks localStorage
   ↓
3a. Session found → Load history from API
3b. No session → Create new via API
   ↓
4. Save session_id to localStorage
   ↓
5. Display chat UI (ready to chat)
```

### Message Flow
```
1. User types message
   ↓
2. Add to UI immediately
   ↓
3. Start SSE stream to API
   ↓
4. Receive chunks in real-time
   ↓
5. Update UI with each chunk
   ↓
6. Stream completes → Finalize message
```

### Data Storage
```
localStorage:
  - chatbot_session_id (only)

API (Source of Truth):
  - Full message history
  - Session management

UI State (Memory):
  - Current messages
  - Streaming state
  - Loading state
```

---

## 9. Testing Checklist

### ✅ Basic Functionality
- [ ] App loads without errors
- [ ] New session creates successfully
- [ ] Session ID saved to localStorage
- [ ] Page refresh restores session
- [ ] History loads correctly
- [ ] Messages send successfully
- [ ] Streaming displays smoothly
- [ ] Auto-scroll works
- [ ] "New Chat" creates new session

### ✅ Error Handling
- [ ] Network error shows message
- [ ] Retry button works
- [ ] Invalid session falls back to new session
- [ ] Stream error handled gracefully

### ✅ Browser Compatibility
- [ ] Chrome works
- [ ] Firefox works
- [ ] Safari works
- [ ] Edge works

### ✅ Responsive Design
- [ ] Desktop view looks good
- [ ] Tablet view works
- [ ] Mobile view responsive

---

## 10. Code Quality Features

✅ **Clean Code**
- Clear naming conventions
- Well-documented functions
- Single responsibility principle
- No code duplication

✅ **Error Handling**
- Try-catch blocks where needed
- User-friendly error messages
- Automatic retry logic
- Graceful fallbacks

✅ **Performance**
- Efficient state updates
- Auto-scroll optimization
- Minimal rebuilds
- Stream cleanup

✅ **UX Design**
- Loading indicators
- Error banners
- Streaming animation
- Smooth transitions

---

## 11. FOR AI IDE: Quick Reference

### Variable Names
- `_chatbotApi` (service instance)
- `_sessionManager` (session handler)
- `_streamService` (SSE handler)
- `_sessionId` (current session)
- `_messages` (message list)
- `_isLoading` (loading state)
- `_isStreaming` (streaming state)

### Class Names
- `ChatbotApi` (API service)
- `SessionManager` (session handler)
- `StreamService` (SSE service)
- `Message` (data model)
- `SessionResult` (result object)
- `ChatScreen` (main screen)
- `MessageBubble` (message widget)
- `ChatInput` (input widget)

### Key Methods
- `initSession()` - Initialize/restore session
- `createSession()` - Create new session
- `getHistory()` - Load message history
- `streamMessage()` - Start SSE stream
- `_sendMessage()` - Send user message
- `_scrollToBottom()` - Auto-scroll chat
- `_resetChat()` - Clear session and start new

### File Sizes (Approximate)
- `message.dart` - 40 lines
- `chatbot_api.dart` - 70 lines
- `session_manager.dart` - 95 lines
- `stream_service.dart` - 45 lines
- `message_bubble.dart` - 85 lines
- `chat_input.dart` - 70 lines
- `chat_screen.dart` - 240 lines
- `main.dart` - 20 lines
- **Total: ~665 lines**

---

## 12. Production Deployment

### Build Commands

```bash
# Development build
flutter build web --web-renderer canvaskit

# Production build (optimized)
flutter build web --release --web-renderer canvaskit

# Production with base href (for subdirectory hosting)
flutter build web --release --base-href "/chatbot/"
```

### Hosting Options

#### Option 1: Firebase Hosting
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login and initialize
firebase login
firebase init hosting

# Deploy
flutter build web --release
firebase deploy --only hosting
```

#### Option 2: Netlify
```bash
# Build
flutter build web --release

# Deploy (drag build/web folder to Netlify)
# Or use Netlify CLI
netlify deploy --dir=build/web --prod
```

#### Option 3: Vercel
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
flutter build web --release
vercel --prod
```

#### Option 4: GitHub Pages
```bash
# Build with base href
flutter build web --release --base-href "/repo-name/"

# Copy build/web/* to gh-pages branch
# Enable GitHub Pages in repository settings
```

---

## 13. Environment Configuration

### Multiple API Environments

Create a config file for different environments:

#### 📄 FILE: `lib/config/api_config.dart`
```dart
/// API configuration for different environments
class ApiConfig {
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'production',
  );

  /// Get base URL based on environment
  static String get baseUrl {
    switch (environment) {
      case 'development':
        return 'http://localhost:8000';
      case 'staging':
        return 'https://staging-api.example.com';
      case 'production':
        return 'https://mitran-chatbot.onrender.com';
      default:
        return 'https://mitran-chatbot.onrender.com';
    }
  }

  /// API timeout duration
  static const Duration timeout = Duration(seconds: 10);

  /// Enable debug logging
  static const bool enableLogging = bool.fromEnvironment(
    'DEBUG_LOG',
    defaultValue: false,
  );
}
```

#### Update `chatbot_api.dart` to use config:
```dart
import '../config/api_config.dart';

class ChatbotApi {
  final String baseUrl;

  ChatbotApi({
    String? baseUrl,
  }) : baseUrl = baseUrl ?? ApiConfig.baseUrl;
  
  // Rest of the code remains same
}
```

#### Build with environment:
```bash
# Development
flutter run -d chrome --dart-define=ENV=development

# Staging
flutter build web --dart-define=ENV=staging

# Production
flutter build web --release --dart-define=ENV=production
```

---

## 14. Advanced Features (Optional)

### Feature 1: Message Persistence Limit

Add to `chat_screen.dart`:

```dart
class _ChatScreenState extends State<ChatScreen> {
  static const int maxMessages = 50; // Keep only last 50 messages
  
  void _addMessage(Message message) {
    setState(() {
      _messages.add(message);
      
      // Trim old messages if exceeds limit
      if (_messages.length > maxMessages) {
        _messages.removeRange(0, _messages.length - maxMessages);
      }
    });
  }
}
```

### Feature 2: Typing Indicator Animation

#### 📄 FILE: `lib/widgets/typing_indicator.dart`
```dart
import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value = _controller.value;
            final delay = index * 0.2;
            final animValue = (value - delay).clamp(0.0, 1.0);

            return Opacity(
              opacity: (animValue * 2).clamp(0.3, 1.0),
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
```

### Feature 3: Copy Message Text

Update `message_bubble.dart`:

```dart
import 'package:flutter/services.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _copyToClipboard(context),
      child: Padding(
        // ... existing code
      ),
    );
  }
}
```

### Feature 4: Connection Status Monitor

#### 📄 FILE: `lib/services/connection_monitor.dart`
```dart
import 'dart:async';
import 'chatbot_api.dart';

class ConnectionMonitor {
  final ChatbotApi api;
  Timer? _timer;
  bool _isOnline = true;

  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get statusStream => _statusController.stream;
  bool get isOnline => _isOnline;

  ConnectionMonitor(this.api);

  void startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnection(),
    );
    _checkConnection();
  }

  void stopMonitoring() {
    _timer?.cancel();
  }

  Future<void> _checkConnection() async {
    final wasOnline = _isOnline;
    _isOnline = await api.checkHealth();

    if (wasOnline != _isOnline) {
      _statusController.add(_isOnline);
      print('Connection: ${_isOnline ? 'ONLINE' : 'OFFLINE'}');
    }
  }

  void dispose() {
    stopMonitoring();
    _statusController.close();
  }
}
```

---

## 15. Troubleshooting Guide

### Issue 1: "Session not found" error on restore

**Cause:** Session expired on server or invalid session ID

**Solution:**
```dart
// Already handled in session_manager.dart
// Falls back to creating new session automatically
```

### Issue 2: Streaming not working

**Symptoms:**
- No response after sending message
- Console shows EventSource errors

**Solutions:**
1. Check browser supports SSE (EventSource)
2. Verify API URL is correct
3. Check CORS headers on API
4. Test API endpoint directly:
```bash
curl "https://your-api.com/v1/chat/stream?session_id=test&text=hello"
```

### Issue 3: localStorage not persisting

**Symptoms:**
- New session created on every refresh
- Session ID not saved

**Solutions:**
1. Check browser allows localStorage
2. Check browser not in incognito mode
3. Clear browser cache and test
4. Check for localStorage quota errors

### Issue 4: Messages not scrolling

**Symptoms:**
- New messages appear but don't auto-scroll

**Solution:**
```dart
// Add delay to _scrollToBottom
void _scrollToBottom() {
  Future.delayed(const Duration(milliseconds: 100), () {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    }
  });
}
```

### Issue 5: CORS errors in browser console

**Cause:** API doesn't allow requests from web origin

**Solution:**
API must include these headers:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type
```

---

## 16. Performance Optimization

### Optimization 1: Debounced Scrolling

```dart
Timer? _scrollDebounce;

void _scrollToBottom() {
  _scrollDebounce?.cancel();
  _scrollDebounce = Timer(const Duration(milliseconds: 100), () {
    if (mounted && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });
}

@override
void dispose() {
  _scrollDebounce?.cancel();
  // ... other dispose code
}
```

### Optimization 2: Batched Stream Updates

```dart
String _streamBuffer = '';
Timer? _batchTimer;

void _onStreamChunk(String chunk) {
  _streamBuffer += chunk;
  
  // Batch UI updates every 50ms
  _batchTimer?.cancel();
  _batchTimer = Timer(const Duration(milliseconds: 50), () {
    if (mounted) {
      setState(() {
        _messages[_messages.length - 1] = _messages.last.copyWith(
          text: _streamBuffer,
        );
      });
    }
  });
}
```

### Optimization 3: ListView Keys

```dart
ListView.builder(
  controller: _scrollController,
  padding: const EdgeInsets.all(16),
  itemCount: _messages.length,
  itemBuilder: (context, index) {
    final message = _messages[index];
    return MessageBubble(
      key: ValueKey('${message.timestamp.millisecondsSinceEpoch}'),
      message: message,
    );
  },
)
```

---

## 17. Security Considerations

### Current Security Features
✅ HTTPS API communication
✅ No sensitive data in localStorage
✅ Input sanitization (Flutter handles)
✅ No authentication tokens stored

### Additional Security (If Needed)

#### Input Validation
```dart
// Add to chat_input.dart
static const int maxMessageLength = 2000;

void _handleSend() {
  final text = controller.text.trim();
  
  if (text.isEmpty) return;
  
  if (text.length > maxMessageLength) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message too long (max $maxMessageLength chars)'),
      ),
    );
    return;
  }
  
  if (enabled) {
    onSend(text);
  }
}
```

#### Rate Limiting
```dart
class RateLimiter {
  final int maxRequests;
  final Duration window;
  final List<DateTime> _requests = [];

  RateLimiter({
    this.maxRequests = 10,
    this.window = const Duration(minutes: 1),
  });

  bool canMakeRequest() {
    final now = DateTime.now();
    _requests.removeWhere((time) => now.difference(time) > window);
    
    if (_requests.length < maxRequests) {
      _requests.add(now);
      return true;
    }
    return false;
  }
}
```

---

## 18. Testing Guide

### Manual Testing Script

```markdown
## Test Script

### 1. First Launch
- [ ] App loads without errors
- [ ] Loading indicator shows
- [ ] Session creates automatically
- [ ] Welcome message appears
- [ ] Input field is enabled

### 2. Send Message
- [ ] Type "Hello"
- [ ] Click send button
- [ ] Message appears on right (user)
- [ ] Response starts streaming
- [ ] Text appears character by character
- [ ] Response completes
- [ ] Input field re-enables

### 3. Session Persistence
- [ ] Refresh page (F5)
- [ ] Previous messages still visible
- [ ] Can send new message
- [ ] Continues same conversation

### 4. New Chat
- [ ] Click refresh icon
- [ ] Confirmation dialog appears
- [ ] Click "New Chat"
- [ ] Messages clear
- [ ] Welcome message appears
- [ ] New session created

### 5. Error Handling
- [ ] Disconnect internet
- [ ] Try to send message
- [ ] Error banner appears
- [ ] Reconnect internet
- [ ] Click retry button
- [ ] Works again

### 6. Edge Cases
- [ ] Try to send empty message (nothing happens)
- [ ] Send very long message (500+ chars)
- [ ] Send multiple messages rapidly
- [ ] Clear localStorage manually
- [ ] Refresh page (new session created)

### 7. Browser Compatibility
- [ ] Test on Chrome
- [ ] Test on Firefox
- [ ] Test on Safari
- [ ] Test on Edge

### 8. Responsive Design
- [ ] Resize browser window
- [ ] Test on tablet size (768px)
- [ ] Test on mobile size (375px)
- [ ] All elements visible and usable
```

---

## 19. API Integration Examples

### Integrating Different Chatbot APIs

#### Example 1: OpenAI API Format
```dart
// If your API returns different format
factory Message.fromJson(Map<String, dynamic> json) {
  return Message(
    text: json['content'] as String,  // OpenAI uses 'content'
    role: json['role'] as String,     // 'user' or 'assistant'
    timestamp: DateTime.now(),
  );
}
```

#### Example 2: Custom Streaming Format
```dart
// If your API uses different SSE format
eventSource.onMessage.listen((html.MessageEvent event) {
  final jsonData = jsonDecode(event.data);
  final chunk = jsonData['delta'] as String?;  // Custom format
  if (chunk != null && chunk.isNotEmpty) {
    controller.add(chunk);
  }
});
```

#### Example 3: REST API (Non-Streaming) Fallback
```dart
// Add to chatbot_api.dart for non-streaming APIs
Future<String> sendMessage({
  required String sessionId,
  required String text,
}) async {
  final uri = Uri.parse('$baseUrl/v1/chat/send');
  
  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'session_id': sessionId,
      'text': text,
    }),
  ).timeout(const Duration(seconds: 30));
  
  if (response.statusCode != 200) {
    throw Exception('Failed to send: ${response.statusCode}');
  }
  
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  return data['text'] as String;
}
```

---

## 20. Final Checklist for AI IDE

### ✅ Files to Create (in order)
1. `pubspec.yaml`
2. `lib/models/message.dart`
3. `lib/services/chatbot_api.dart`
4. `lib/services/session_manager.dart`
5. `lib/services/stream_service.dart`
6. `lib/widgets/message_bubble.dart`
7. `lib/widgets/chat_input.dart`
8. `lib/screens/chat_screen.dart`
9. `lib/main.dart`

### ✅ Key Points for AI
- **Do NOT rename** `ChatbotApi` class
- **Do NOT rename** `chatbot_session_id` localStorage key
- **Do NOT modify** error handling logic
- **Do NOT add** unnecessary dependencies
- **Do NOT change** the file structure
- **Copy code exactly** as provided
- **Test after** each file creation
- **Verify imports** are correct

### ✅ After Implementation
```bash
# 1. Get dependencies
flutter pub get

# 2. Analyze code
flutter analyze

# 3. Run app
flutter run -d chrome

# 4. Test basic flow
# - App loads
# - Send message
# - See response
# - Refresh page
# - Session persists

# 5. Build for production
flutter build web --release
```

---

## Summary

This PRD provides a **complete, production-ready** Flutter Web chatbot implementation with:

✅ **Clean Architecture** - Well-organized, maintainable code
✅ **Generic API Integration** - Works with any chatbot API
✅ **Proper Session Management** - localStorage + API history
✅ **Real-time Streaming** - SSE for live responses
✅ **Error Handling** - Comprehensive error management
✅ **Responsive Design** - Works on all devices
✅ **Simple & Efficient** - ~665 lines of clean code
✅ **AI IDE Ready** - Clear instructions, copy-paste code

**Total Implementation Time: ~2-3 hours**

**Code Quality: Production-ready**

**Maintenance: Easy - clear structure, well-documented**